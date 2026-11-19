import Foundation

private func pick<T>(_ items: [T], dice: Dice) -> T? {
    guard !items.isEmpty else { return nil }
    return items[Int(dice(0...Double(items.count - 1)).rounded())]
}

struct ClimbBehavior: Behavior {
    enum Phase: Equatable { case approaching, climbing, crossing, sliding, resting }

    private let dice: Dice
    private var fallback: ExploreBehavior
    private(set) var wall: Wall?
    private(set) var phase = Phase.approaching
    private(set) var climbs = 0
    private var exitRight = true
    private var stride = 0.0
    private var restTime = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        fallback = ExploreBehavior(pet: pet, dice: dice)
        wall = pick(pet.world.walls(on: pet.stage), dice: dice)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard let wall else {
            wall = pick(pet.world.walls(on: pet.stage), dice: dice)
            fallback.step(&pet, dt: dt, speed: speed)
            return
        }
        if phase == .climbing, !pet.world.walls(on: pet.stage).contains(wall) {
            pet.letGo()
            rest(for: 1)
        }
        let boost = pet.stage.travelBoost
        switch phase {
        case .approaching:
            guard Navigator.step(&pet, to: Goal(surface: wall.base, x: wall.standCenter), speed: 16 * speed * boost, dt: dt) else { return }
            pet.x = wall.climbX
            pet.facingRight = wall.faceRight
            pet.cling(at: pet.feet)
            phase = .climbing
        case .climbing:
            let rise = 14 * speed * dt
            stride += rise
            pet.cling(at: max(wall.top.y, pet.feet - rise))
            guard pet.feet <= wall.top.y else { return }
            pet.x = wall.faceRight ? wall.x + 1 : wall.x - Pet.width - 1
            pet.stand(on: wall.top.y)
            climbs += 1
            chooseExit(from: wall.top, stage: pet.stage)
        case .crossing:
            let edge = exitRight ? wall.top.maxX - Pet.width / 2 : wall.top.minX + Pet.width / 2
            guard Navigator.step(&pet, to: Goal(surface: wall.top.y, x: edge), speed: 12 * speed * boost, dt: dt) else { return }
            pet.x = exitRight ? wall.top.maxX : wall.top.minX - Pet.climbWidth
            pet.facingRight = !exitRight
            pet.cling(at: pet.feet)
            phase = .sliding
        case .sliding:
            if pet.slide(down: 30 * speed * dt) {
                pet.x = pet.x.clamped(to: 0...pet.maxX)
                rest(for: dice(1...2.5))
            }
        case .resting:
            restTime -= dt
            guard restTime <= 0 else { return }
            self.wall = pick(pet.world.walls(on: pet.stage), dice: dice)
            phase = .approaching
        }
    }

    private mutating func chooseExit(from top: Platform, stage: Stage) {
        let exits = [true, false].filter { $0 ? top.maxX + Pet.width <= stage.width : top.minX - Pet.width >= 0 }
        guard let exit = pick(exits, dice: dice) else {
            rest(for: dice(2...4))
            return
        }
        exitRight = exit
        phase = .crossing
    }

    private mutating func rest(for seconds: Double) {
        restTime = seconds
        phase = .resting
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        guard pet.clinging else {
            if wall == nil { return fallback.scene(pet, clock: clock) }
            return SceneSnapshot(pet: pet.item(phase == .resting ? pet.sprites.rest : pet.walkingSprite))
        }
        let frame = phase == .climbing ? Int(stride / 2) % 2 : 0
        let sprite = pet.sprites.climb[frame]
        return SceneSnapshot(pet: .init(
            sprite: sprite, facingRight: pet.facingRight, x: pet.x.rounded(), y: max(0, pet.feet - Double(sprite.height)).rounded()
        ))
    }
}

struct LedgeBehavior: Behavior {
    static let room = 8.0

    private let dice: Dice
    private var fallback: ExploreBehavior
    private(set) var ledge: Ledge?
    private(set) var sitting = false
    private var timer = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        fallback = ExploreBehavior(pet: pet, dice: dice)
        ledge = pick(pet.world.ledges(on: pet.stage, room: Self.room), dice: dice)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard let ledge, pet.world.ledges(on: pet.stage, room: Self.room).contains(ledge) else {
            sitting = false
            ledge = pick(pet.world.ledges(on: pet.stage, room: Self.room), dice: dice)
            fallback.step(&pet, dt: dt, speed: speed)
            return
        }
        guard sitting else {
            let goal = Goal(surface: ledge.top.y, x: ledge.edge - ledge.outward)
            guard Navigator.step(&pet, to: goal, speed: 16 * speed * pet.stage.travelBoost, dt: dt) else { return }
            pet.facingRight = ledge.right
            sitting = true
            timer = dice(6...12)
            return
        }
        timer -= dt
        guard timer <= 0 else { return }
        sitting = false
        self.ledge = pick(pet.world.ledges(on: pet.stage, room: Self.room), dice: dice)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        guard sitting, let ledge else {
            return ledge == nil ? fallback.scene(pet, clock: clock) : SceneSnapshot(pet: pet.item(pet.walkingSprite))
        }
        let legs = pet.sprites.dangle[Int(clock * 1.5) % 2]
        let x = ledge.right ? ledge.edge : ledge.edge - Double(legs.width)
        return SceneSnapshot(
            pet: pet.item(pet.sprites.rest),
            prop: .init(sprite: legs, facingRight: ledge.right, x: x, y: ledge.top.y)
        )
    }
}

struct KnockBehavior: Behavior {
    enum Phase: Equatable { case approaching, pushing, watching }
    static let room = 10.0
    static let minWidth = Pet.width + 14

    private let dice: Dice
    private var fallback: ExploreBehavior
    private(set) var ledge: Ledge?
    private(set) var phase = Phase.approaching
    private(set) var pot = 0.0
    private(set) var knocked = 0
    private var fall = Fall(feet: 0)
    private var drift = 0.0
    private var timer = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        fallback = ExploreBehavior(pet: pet, dice: dice)
        setUp(pick(Self.ledges(pet), dice: dice))
    }

    private static func ledges(_ pet: Pet) -> [Ledge] {
        pet.world.ledges(on: pet.stage, room: room, minWidth: minWidth)
    }

    private var potWidth: Double { Double(Sprites.pot.width) }
    private var broken: Bool { phase == .watching && fall.supported }

    private mutating func setUp(_ ledge: Ledge?) {
        self.ledge = ledge
        phase = .approaching
        guard let ledge else { return }
        pot = ledge.right ? ledge.top.maxX - 8 - potWidth : ledge.top.minX + 8
        fall = Fall(feet: ledge.top.y)
        drift = 0
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard let ledge else {
            setUp(pick(Self.ledges(pet), dice: dice))
            fallback.step(&pet, dt: dt, speed: speed)
            return
        }
        if phase != .watching, !Self.ledges(pet).contains(ledge) {
            setUp(pick(Self.ledges(pet), dice: dice))
            return
        }
        switch phase {
        case .approaching:
            let behind = ledge.right ? pot - Pet.width / 2 - 1 : pot + potWidth + Pet.width / 2 + 1
            let goal = Goal(surface: ledge.top.y, x: behind)
            guard Navigator.step(&pet, to: goal, speed: 16 * speed * pet.stage.travelBoost, dt: dt) else { return }
            pet.facingRight = ledge.right
            phase = .pushing
        case .pushing:
            pet.walk(toward: ledge.edge - ledge.outward * 4, speed: 5 * speed, dt: dt)
            pet.facingRight = ledge.right
            pot = ledge.right ? max(pot, pet.x + Pet.width) : min(pot, pet.x - potWidth)
            fall.update(dt, x: pot + potWidth / 2, world: pet.world, on: pet.stage)
            guard !fall.supported else { return }
            drift = ledge.outward * 10
            knocked += 1
            phase = .watching
            timer = 3
        case .watching:
            if !fall.supported {
                pot = (pot + drift * dt).clamped(to: 0...(pet.stage.width - potWidth))
                fall.update(dt, x: pot + potWidth / 2, world: pet.world, on: pet.stage)
                return
            }
            timer -= dt
            if timer <= 0 { setUp(pick(Self.ledges(pet), dice: dice)) }
        }
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        guard ledge != nil else { return fallback.scene(pet, clock: clock) }
        let sprite = broken ? Sprites.shards : Sprites.pot
        let watching = phase == .watching && !fall.supported
        return SceneSnapshot(
            pet: pet.item(phase == .pushing || pet.moving ? pet.walkingSprite : pet.sprites.walk[0]),
            prop: .init(sprite: sprite, x: pot.rounded(), y: (fall.feet - Double(sprite.height)).rounded()),
            effects: watching ? Effects.blinking(Sprites.exclamation, over: pet, clock: clock) : []
        )
    }
}
