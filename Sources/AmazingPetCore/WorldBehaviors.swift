import Foundation

struct Goal: Equatable {
    var surface: Double
    var x: Double
}

enum Navigator {
    static let arrivalDistance = 1.0

    static func step(_ pet: inout Pet, to goal: Goal, speed: Double, dt: Double) -> Bool {
        if pet.isAirborne {
            pet.walk(toward: goal.x, speed: speed, dt: dt)
            return false
        }
        let stage = pet.stage
        let current = pet.world.surface(at: pet.feet, x: pet.center, on: stage)
        if abs(pet.feet - goal.surface) < 0.01, current?.contains(goal.x) ?? true {
            pet.walk(toward: goal.x, speed: speed, dt: dt)
            return abs(pet.center - goal.x) < arrivalDistance
        }
        if goal.surface < pet.feet {
            let target = pet.world.surface(under: (goal.x, goal.surface - 0.5), on: stage)
            let launch = pet.center.clamped(to: (target.minX + 4)...(target.maxX - 4))
            if abs(pet.center - launch) < arrivalDistance {
                pet.leap(height: pet.feet - target.y + 4)
            } else {
                pet.walk(toward: launch, speed: speed, dt: dt)
            }
            return false
        }
        if let current, current.contains(goal.x) {
            pet.walk(toward: exit(from: current, toward: goal.x, on: stage) ?? goal.x, speed: speed, dt: dt)
        } else {
            pet.walk(toward: goal.x, speed: speed, dt: dt)
        }
        return false
    }

    static func exit(from platform: Platform, toward x: Double, on stage: Stage) -> Double? {
        let reachable = (Pet.width / 2)...(stage.width - Pet.width / 2)
        return [platform.minX - 1, platform.maxX + 1]
            .filter(reachable.contains)
            .min { abs($0 - x) < abs($1 - x) }
    }

    static func randomGoal(for pet: Pet, dice: Dice) -> Goal {
        let surfaces = pet.world.surfaces(on: pet.stage).filter { $0.width >= Pet.width + 4 }
        let surface = surfaces[Int(dice(0...Double(surfaces.count - 1)).rounded())]
        return Goal(surface: surface.y, x: dice((surface.minX + Pet.width / 2)...(surface.maxX - Pet.width / 2)))
    }
}

struct ExploreBehavior: Behavior {
    static let patience = 14.0
    private let dice: Dice
    private(set) var goal: Goal
    private var patienceLeft = Self.patience

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        goal = Navigator.randomGoal(for: pet, dice: dice)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard !pet.isPaused else { return }
        patienceLeft -= dt
        let arrived = Navigator.step(&pet, to: goal, speed: 16 * speed, dt: dt)
        guard arrived || patienceLeft <= 0 else { return }
        pet.pause = dice(0.8...3)
        goal = Navigator.randomGoal(for: pet, dice: dice)
        patienceLeft = Self.patience
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(pet: pet.item(pet.walkingSprite))
    }
}

struct PeekabooBehavior: Behavior {
    enum Phase: Equatable { case going, hiding, peeking }

    private let dice: Dice
    private var fallback: ExploreBehavior
    private(set) var spot: Platform?
    private(set) var phase = Phase.going
    private(set) var peeks = 0
    private var timer = 0.0
    private var peekRight = true

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        fallback = ExploreBehavior(pet: pet, dice: dice)
        spot = Self.pickSpot(for: pet, dice: dice)
    }

    private static func pickSpot(for pet: Pet, dice: Dice) -> Platform? {
        let spots = pet.world.hidingSpots(on: pet.stage)
        guard !spots.isEmpty else { return nil }
        return spots[Int(dice(0...Double(spots.count - 1)).rounded())]
    }

    private var hideX: Double { spot.map { ($0.minX + $0.maxX) / 2 } ?? 0 }

    private var peekX: Double {
        guard let spot else { return 0 }
        return peekRight ? spot.maxX + Pet.width / 2 - 7 : spot.minX - Pet.width / 2 + 7
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        if spot == nil { spot = Self.pickSpot(for: pet, dice: dice) }
        guard let spot else {
            fallback.step(&pet, dt: dt, speed: speed)
            return
        }
        timer -= dt
        switch phase {
        case .going:
            if Navigator.step(&pet, to: Goal(surface: spot.y, x: hideX), speed: 16 * speed, dt: dt) {
                phase = .hiding
                timer = dice(2...4)
            }
        case .hiding:
            if !Navigator.step(&pet, to: Goal(surface: spot.y, x: hideX), speed: 10 * speed, dt: dt) { return }
            guard timer <= 0 else { return }
            phase = .peeking
            peekRight = dice(0...1) < 0.5
            timer = dice(1.2...2.2)
        case .peeking:
            let there = Navigator.step(&pet, to: Goal(surface: spot.y, x: peekX), speed: 10 * speed, dt: dt)
            if there { pet.facingRight = peekRight }
            guard there, timer <= 0 else { return }
            peeks += 1
            phase = .hiding
            timer = dice(1.5...3.5)
            if peeks.isMultiple(of: 3) {
                self.spot = Self.pickSpot(for: pet, dice: dice)
                phase = .going
            }
        }
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        let effects = phase == .peeking && !pet.moving ? Effects.blinking(Sprites.exclamation, over: pet, clock: clock) : []
        return SceneSnapshot(pet: pet.item(pet.walkingSprite), effects: effects)
    }
}

struct CursorBehavior: Behavior {
    private let dice: Dice
    private var fallback: ExploreBehavior
    private var pounceIn = 1.0
    private(set) var pounces = 0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        fallback = ExploreBehavior(pet: pet, dice: dice)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard let cursor = pet.world.cursor else {
            fallback.step(&pet, dt: dt, speed: speed)
            return
        }
        let surface = pet.world.surface(under: cursor, on: pet.stage)
        let side = pet.center < cursor.x ? -10.0 : 10.0
        let waitX = (cursor.x + side).clamped(to: (surface.minX + Pet.width / 2)...(surface.maxX - Pet.width / 2))
        guard Navigator.step(&pet, to: Goal(surface: surface.y, x: waitX), speed: 20 * speed, dt: dt) else { return }

        pet.facingRight = cursor.x > pet.center
        pounceIn -= dt
        guard pounceIn <= 0 else { return }
        pounceIn = dice(1.2...2.8)
        pounces += 1
        pet.leap(height: (pet.feet - cursor.y).clamped(to: 6...30))
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        let watching = pet.world.cursor != nil && !pet.moving && !pet.isAirborne
        return SceneSnapshot(
            pet: pet.item(pet.walkingSprite),
            effects: watching ? Effects.blinking(Sprites.heart, over: pet, clock: clock) : []
        )
    }
}

struct PerchBehavior: Behavior {
    private(set) var asleep = false

    init(pet: Pet, dice: Dice) {}

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard !asleep else { return }
        let perch = pet.world.highestPerch(on: pet.stage)
        let goal = Goal(surface: perch.y, x: (perch.minX + perch.maxX) / 2)
        asleep = Navigator.step(&pet, to: goal, speed: 14 * speed, dt: dt)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        guard asleep else { return SceneSnapshot(pet: pet.item(pet.walkingSprite)) }
        return SleepBehavior().scene(pet, clock: clock)
    }
}
