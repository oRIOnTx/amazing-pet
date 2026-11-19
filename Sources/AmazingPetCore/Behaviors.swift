import Foundation

protocol Behavior {
    mutating func step(_ pet: inout Pet, dt: Double, speed: Double)
    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot
}

struct SleepBehavior: Behavior {
    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {}

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(pet: pet.item(pet.sprites.rest), effects: Effects.floating(Sprites.zzz, from: pet, clock: clock, rate: 0.35))
    }
}

struct YarnBehavior: Behavior {
    static let size = 6.0
    private let dice: Dice
    private(set) var ball: Double
    private(set) var velocity = 0.0
    private var fall: Fall
    private var roll = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        let lane = pet.lane
        let start = pet.facingRight ? pet.x + 20 : pet.x - 10
        ball = start.clamped(to: lane.minX...max(lane.minX, lane.maxX - Self.size))
        fall = Fall(feet: lane.y)
    }

    private var center: Double { ball + Self.size / 2 }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        rollBall(dt, pet: pet)
        guard !pet.isPaused else { return }
        let boost = pet.stage.travelBoost
        let distance = center - pet.center
        let sameLane = fall.supported && !pet.isAirborne && abs(pet.feet - fall.feet) < 0.01
        if !sameLane || abs(distance) > 11.5 {
            let surface = pet.world.surface(under: (center, fall.feet - 0.01), on: pet.stage)
            _ = Navigator.step(&pet, to: Goal(surface: surface.y, x: center), speed: 7 * speed * boost, dt: dt)
        } else if velocity == 0 {
            pet.facingRight = distance > 0
            velocity = (distance > 0 ? 1 : -1) * dice(16...30) * speed * boost
            pet.pause = dice(0.4...1.2)
        }
    }

    private mutating func rollBall(_ dt: Double, pet: Pet) {
        ball += velocity * dt
        roll += abs(velocity * dt)
        velocity *= pow(0.3, dt)
        if abs(velocity) < 1 { velocity = 0 }
        let maxX = pet.stage.width - Self.size
        if ball < 0 || ball > maxX {
            ball = ball.clamped(to: 0...maxX)
            velocity = -velocity * 0.5
        }
        fall.update(dt, x: center, world: pet.world, on: pet.stage)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(
            pet: pet.item(pet.walkingSprite),
            prop: .init(sprite: Sprites.yarn[Int(roll / 2) % 2], x: ball.rounded(), y: (fall.feet - Self.size).rounded())
        )
    }
}

struct MouseBehavior: Behavior {
    static let size = 8.0
    private let dice: Dice
    private var lane: Platform
    private(set) var mouse: Double
    private var target: Double
    private var restTime = 0.0
    private var fleeTime = 0.0
    private var facingRight = true
    private var stride = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        lane = pet.lane
        let maxX = max(lane.minX, lane.maxX - Self.size)
        mouse = (pet.facingRight ? pet.x + 22 : pet.x - 12).clamped(to: lane.minX...maxX)
        target = mouse
    }

    private var maxX: Double { max(lane.minX, lane.maxX - Self.size) }
    private var center: Double { mouse + Self.size / 2 }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        followWorld(pet)
        let boost = pet.stage.travelBoost
        let sameLane = !pet.isAirborne && abs(pet.feet - lane.y) < 0.01
        let distance = center - pet.center
        if fleeTime > 0 {
            fleeTime -= dt
        } else if sameLane && abs(distance) < 10 {
            target = escapeTarget(awayFrom: distance)
            fleeTime = 1.2
        }
        moveMouse(dt: dt, speed: (fleeTime > 0 ? 28 : 11) * speed * boost)

        guard !pet.isPaused else { return }
        if sameLane && abs(distance) < 7 {
            pet.pause = 0.5
        } else {
            _ = Navigator.step(&pet, to: Goal(surface: lane.y, x: center), speed: 15 * speed * boost, dt: dt)
        }
    }

    private mutating func followWorld(_ pet: Pet) {
        guard pet.world.surface(at: lane.y, x: center, on: pet.stage) == nil else { return }
        lane = pet.world.surface(under: (center, lane.y), on: pet.stage)
        mouse = mouse.clamped(to: lane.minX...maxX)
        target = target.clamped(to: lane.minX...maxX)
    }

    private func escapeTarget(awayFrom distance: Double) -> Double {
        if distance > 0 && mouse < maxX - 10 { return dice((mouse + 10)...maxX) }
        if distance <= 0 && mouse > lane.minX + 10 { return dice(lane.minX...(mouse - 10)) }
        return distance > 0 ? dice(lane.minX...min(maxX, lane.minX + 6)) : dice(max(lane.minX, maxX - 6)...maxX)
    }

    private mutating func moveMouse(dt: Double, speed: Double) {
        let delta = target - mouse
        if abs(delta) > 0.5 {
            facingRight = delta > 0
            let step = delta.clamped(to: -speed * dt ... speed * dt)
            mouse += step
            stride += abs(step)
            return
        }
        restTime -= dt
        if restTime <= 0 {
            target = dice(lane.minX...maxX)
            restTime = dice(0.6...2.5)
        }
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(
            pet: pet.item(pet.runningSprite),
            prop: .init(sprite: Sprites.toyMouse[Int(stride / 2) % 2], facingRight: facingRight, x: mouse.rounded(), y: lane.y - 4)
        )
    }
}

struct LaserBehavior: Behavior {
    static let size = 3.0
    private let dice: Dice
    private(set) var dot: Double
    private var height: Double
    private var surface: Double
    private var target: (x: Double, height: Double, surface: Double)
    private var hopTime = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        dot = pet.center
        surface = pet.lane.y
        height = surface - 6
        target = (dot, height, surface)
        hop(pet)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        let reach = 70 * pet.stage.travelBoost * dt
        dot += (target.x - dot).clamped(to: -reach...reach)
        height += (target.height - height).clamped(to: -reach...reach)
        if abs(target.x - dot) < 0.5 { surface = target.surface }
        hopTime -= dt * speed
        if hopTime <= 0 { hop(pet) }

        guard !pet.isPaused else { return }
        let sameLane = !pet.isAirborne && abs(pet.feet - surface) < 0.01
        if sameLane && abs(dot + Self.size / 2 - pet.center) < 3 {
            pet.pause = 0.3
            hopTime = min(hopTime, 0.3)
            if height < surface - 8 { pet.jump() }
        } else {
            let goal = Goal(surface: surface, x: dot + Self.size / 2)
            _ = Navigator.step(&pet, to: goal, speed: 24 * speed * pet.stage.travelBoost, dt: dt)
        }
    }

    private mutating func hop(_ pet: Pet) {
        let surfaces = pet.world.surfaces(on: pet.stage).filter { $0.width >= Pet.width }
        let lane = dice(0...1) < 0.6 ? pet.lane : surfaces[Int(dice(0...Double(surfaces.count - 1)).rounded())]
        let maxX = lane.maxX - Self.size
        var next = dice(lane.minX...maxX)
        if abs(next - dot) < 8 { next += dot < (lane.minX + lane.maxX) / 2 ? 16 : -16 }
        let height = dice(max(1, lane.y - 26)...(lane.y - 3)).rounded()
        target = (next.clamped(to: lane.minX...maxX), max(0, height), lane.y)
        hopTime = dice(0.5...1.6)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(
            pet: pet.item(pet.runningSprite),
            prop: .init(sprite: Sprites.laser[Int(clock * 6) % 2], x: dot.rounded(), y: height.rounded())
        )
    }
}

struct ZoomiesBehavior: Behavior {
    static let patience = 6.0
    private let dice: Dice
    private let leaps: Bool
    private let pace: Double
    private(set) var target: Goal
    private var patienceLeft = Self.patience

    init(pet: Pet, dice: Dice, leaps: Bool = true, pace: Double = 45) {
        self.dice = dice
        self.leaps = leaps
        self.pace = pace
        target = Goal(surface: pet.lane.y, x: pet.center)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard !pet.isPaused else { return }
        patienceLeft -= dt
        let arrived = Navigator.step(&pet, to: target, speed: pace * speed, dt: dt)
        if arrived || patienceLeft <= 0 {
            pet.pause = dice(0.2...1.0)
            target = nextTarget(pet)
            patienceLeft = Self.patience
            return
        }
        if leaps, abs(pet.feet - target.surface) < 0.01, dice(0...1) < dt * 0.5 { pet.jump() }
    }

    private func nextTarget(_ pet: Pet) -> Goal {
        if leaps, dice(0...1) < 0.3 { return Navigator.randomGoal(for: pet, dice: dice) }
        let lane = pet.lane
        let half = Pet.width / 2
        guard lane.width > Pet.width else { return Goal(surface: lane.y, x: pet.center) }
        return Goal(surface: lane.y, x: dice((lane.minX + half)...(lane.maxX - half)))
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(pet: pet.item(pet.runningSprite))
    }
}

struct ButterflyBehavior: Behavior {
    static let size = 5.0
    private let dice: Dice
    private let frames: [Sprite]
    private(set) var position: (x: Double, y: Double)
    private var target: (x: Double, y: Double)
    private var flutter = 0.0
    private(set) var jumps = 0

    init(pet: Pet, dice: Dice, frames: [Sprite] = Sprites.butterfly) {
        self.dice = dice
        self.frames = frames
        let x = pet.facingRight ? min(pet.x + 24, pet.stage.width - Self.size) : max(pet.x - 12, 0)
        position = (x, max(0, pet.feet - 18))
        target = position
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        flutter += dt
        fly(dt: dt, speed: 16 * speed * pet.stage.travelBoost, pet: pet)

        let center = position.x + Self.size / 2
        let distance = center - pet.center
        if abs(distance) < 4 && !pet.isAirborne && position.y > pet.feet - 24 {
            pet.jump()
            jumps += 1
            target = (dice(0...(pet.stage.width - Self.size)), max(0, pet.feet - 28))
        } else if abs(distance) >= 4 {
            let surface = pet.world.surface(under: (center, position.y), on: pet.stage)
            _ = Navigator.step(&pet, to: Goal(surface: surface.y, x: center), speed: 13 * speed * pet.stage.travelBoost, dt: dt)
        }
    }

    private mutating func fly(dt: Double, speed: Double, pet: Pet) {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = (dx * dx + dy * dy).squareRoot()
        guard distance > 1 else {
            target = nextTarget(pet)
            return
        }
        let step = min(1, speed * dt / distance)
        position = (position.x + dx * step, position.y + dy * step)
    }

    private func nextTarget(_ pet: Pet) -> (x: Double, y: Double) {
        let surfaces = pet.world.surfaces(on: pet.stage)
        let lane = dice(0...1) < 0.6 ? pet.lane : surfaces[Int(dice(0...Double(surfaces.count - 1)).rounded())]
        let x = dice(max(0, lane.minX)...max(0, lane.maxX - Self.size))
        return (x, max(0, lane.y - dice(8...26)))
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        let wobble = (sin(flutter * 5) * 1.5).rounded()
        let y = (position.y + wobble).clamped(to: 0...(pet.stage.height - 4))
        return SceneSnapshot(
            pet: pet.item(pet.walkingSprite),
            prop: .init(sprite: frames[Int(flutter * 8) % frames.count], x: position.x.rounded(), y: y.rounded())
        )
    }
}

struct AlertBehavior: Behavior {
    enum Placement { case inFront(y: Double), around(y: Double) }
    enum EffectStyle { case floating(rate: Double), blinking }

    let frames: [Sprite]
    let placement: Placement
    let effect: Sprite
    let effectStyle: EffectStyle
    var shaking = false

    static let overheated = AlertBehavior(
        frames: Sprites.thermometer, placement: .inFront(y: 2), effect: Sprites.sweat, effectStyle: .floating(rate: 0.8)
    )
    static let hungry = AlertBehavior(
        frames: [Sprites.bowl], placement: .inFront(y: 9), effect: Sprites.fish, effectStyle: .floating(rate: 0.4)
    )

    static func memoryTight(_ home: Home) -> AlertBehavior {
        AlertBehavior(frames: [home.sprite], placement: .around(y: 0), effect: home.unease, effectStyle: .floating(rate: 0.3))
    }

    static func memoryFull(_ home: Home) -> AlertBehavior {
        AlertBehavior(
            frames: [home.sprite], placement: .around(y: 0), effect: Sprites.exclamation, effectStyle: .blinking, shaking: true
        )
    }

    func prepare(_ pet: inout Pet) {
        let width = Double(frames[0].width)
        switch placement {
        case .inFront:
            let room = width + 1
            if pet.facingRight && pet.x + Pet.width + room > pet.stage.width { pet.facingRight = false }
            if !pet.facingRight && pet.x - room < 0 { pet.facingRight = true }
        case .around:
            let margin = (width - Pet.width) / 2 + 1
            pet.x = pet.x.clamped(to: margin...(pet.stage.width - Pet.width - margin))
        }
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {}

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        let sprite = frames[Int(clock * 2) % frames.count]
        let effects = switch effectStyle {
        case .floating(let rate): Effects.floating(effect, from: pet, clock: clock, rate: rate)
        case .blinking: Effects.blinking(effect, over: pet, clock: clock)
        }
        var petItem = pet.item(pet.sprites.rest)
        var prop = propItem(sprite, pet: pet)
        let jolt = shake(at: clock)
        petItem.x += jolt
        prop.x += jolt
        return SceneSnapshot(pet: petItem, prop: prop, effects: effects)
    }

    func shake(at clock: Double) -> Double {
        shaking && Int(clock * 4) % 2 == 1 ? 1 : 0
    }

    private func propItem(_ sprite: Sprite, pet: Pet) -> SceneSnapshot.Item {
        let width = Double(sprite.width)
        let maxX = pet.stage.width - width
        switch placement {
        case .inFront(let y):
            let x = pet.facingRight ? pet.x + Pet.width : pet.x - width
            return .init(sprite: sprite, x: x.clamped(to: 0...maxX).rounded(), y: pet.ground + y)
        case .around(let y):
            let x = pet.x - (width - Pet.width) / 2
            return .init(
                sprite: sprite, facingRight: pet.facingRight, x: x.clamped(to: 0...maxX).rounded(), y: pet.ground + y
            )
        }
    }
}
