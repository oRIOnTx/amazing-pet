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
    private var roll = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        ball = pet.facingRight ? min(pet.x + 20, pet.stage.width - Self.size) : max(pet.x - 10, 0)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        rollBall(dt, stage: pet.stage)
        guard !pet.isPaused else { return }
        let distance = ball + Self.size / 2 - pet.center
        if abs(distance) > 11.5 {
            pet.walk(toward: ball + Self.size / 2, speed: 7 * speed, dt: dt)
        } else if velocity == 0 {
            pet.facingRight = distance > 0
            velocity = (distance > 0 ? 1 : -1) * dice(16...30) * speed * kickBoost(pet.stage)
            pet.pause = dice(0.4...1.2)
        }
    }

    private func kickBoost(_ stage: Stage) -> Double {
        max(1, (stage.width / Stage.menuBar.width).squareRoot())
    }

    private mutating func rollBall(_ dt: Double, stage: Stage) {
        ball += velocity * dt
        roll += abs(velocity * dt)
        velocity *= pow(0.3, dt)
        if abs(velocity) < 1 { velocity = 0 }
        let maxX = stage.width - Self.size
        if ball < 0 || ball > maxX {
            ball = ball.clamped(to: 0...maxX)
            velocity = -velocity * 0.5
        }
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(
            pet: pet.item(pet.walkingSprite),
            prop: .init(sprite: Sprites.yarn[Int(roll / 2) % 2], x: ball.rounded(), y: pet.stage.height - Self.size)
        )
    }
}

struct MouseBehavior: Behavior {
    static let size = 8.0
    private let dice: Dice
    private let maxX: Double
    private(set) var mouse: Double
    private var target: Double
    private var restTime = 0.0
    private var fleeTime = 0.0
    private var facingRight = true
    private var stride = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        maxX = pet.stage.width - Self.size
        mouse = pet.facingRight ? min(pet.x + 22, maxX) : max(pet.x - 12, 0)
        target = mouse
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        let distance = mouse + Self.size / 2 - pet.center
        if fleeTime > 0 {
            fleeTime -= dt
        } else if abs(distance) < 10 {
            target = escapeTarget(awayFrom: distance)
            fleeTime = 1.2
        }
        moveMouse(dt: dt, speed: (fleeTime > 0 ? 28 : 11) * speed)

        guard !pet.isPaused else { return }
        if abs(distance) < 7 {
            pet.pause = 0.5
        } else {
            pet.walk(toward: mouse + Self.size / 2, speed: 15 * speed, dt: dt)
        }
    }

    private func escapeTarget(awayFrom distance: Double) -> Double {
        if distance > 0 && mouse < maxX - 10 { return dice((mouse + 10)...maxX) }
        if distance <= 0 && mouse > 10 { return dice(0...(mouse - 10)) }
        return distance > 0 ? dice(0...6) : dice((maxX - 6)...maxX)
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
            target = dice(0...maxX)
            restTime = dice(0.6...2.5)
        }
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(
            pet: pet.item(pet.runningSprite),
            prop: .init(sprite: Sprites.toyMouse[Int(stride / 2) % 2], facingRight: facingRight, x: mouse.rounded(), y: pet.ground + 8)
        )
    }
}

struct LaserBehavior: Behavior {
    static let size = 3.0
    private let dice: Dice
    private let stage: Stage
    private(set) var dot: Double
    private var target: Double
    private var height: Double
    private var hopTime = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        stage = pet.stage
        dot = pet.center
        target = dot
        height = pet.ground + 6
        hop()
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        dot += (target - dot).clamped(to: -70 * dt ... 70 * dt)
        hopTime -= dt * speed
        if hopTime <= 0 { hop() }

        guard !pet.isPaused else { return }
        if abs(dot + Self.size / 2 - pet.center) < 3 {
            pet.pause = 0.3
            hopTime = min(hopTime, 0.3)
            if height < pet.ground + 4 { pet.jump() }
        } else {
            pet.walk(toward: dot + Self.size / 2, speed: 24 * speed, dt: dt)
        }
    }

    private mutating func hop() {
        let maxX = stage.width - Self.size
        var next = dice(0...maxX)
        if abs(next - dot) < 8 { next += dot < stage.width / 2 ? 16 : -16 }
        target = next.clamped(to: 0...maxX)
        height = dice(max(1, stage.ground - 14)...(stage.ground + 9)).rounded()
        hopTime = dice(0.5...1.6)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(
            pet: pet.item(pet.runningSprite),
            prop: .init(sprite: Sprites.laser[Int(clock * 6) % 2], x: dot.rounded(), y: height)
        )
    }
}

struct ZoomiesBehavior: Behavior {
    private let dice: Dice
    private(set) var target: Double

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        target = pet.center
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard !pet.isPaused else { return }
        if abs(target - pet.center) <= 0.5 {
            pet.pause = dice(0.2...1.0)
            target = dice((Pet.width / 2)...(pet.stage.width - Pet.width / 2))
            return
        }
        pet.walk(toward: target, speed: 45 * speed, dt: dt)
        if dice(0...1) < dt * 0.5 { pet.jump() }
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(pet: pet.item(pet.runningSprite))
    }
}

struct ButterflyBehavior: Behavior {
    static let size = 5.0
    private let dice: Dice
    private(set) var position: (x: Double, y: Double)
    private var target: (x: Double, y: Double)
    private var flutter = 0.0
    private(set) var jumps = 0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        position = (pet.facingRight ? min(pet.x + 24, pet.stage.width - Self.size) : max(pet.x - 12, 0), max(0, pet.ground - 6))
        target = position
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        flutter += dt
        fly(dt: dt, speed: 16 * speed, stage: pet.stage)

        let distance = position.x + Self.size / 2 - pet.center
        if abs(distance) < 4 && !pet.isAirborne && position.y > pet.ground - 12 {
            pet.jump()
            jumps += 1
            target = (dice(0...(pet.stage.width - Self.size)), max(0, pet.ground - 16))
        } else if abs(distance) >= 4 {
            pet.walk(toward: position.x + Self.size / 2, speed: 13 * speed, dt: dt)
        }
    }

    private mutating func fly(dt: Double, speed: Double, stage: Stage) {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = (dx * dx + dy * dy).squareRoot()
        guard distance > 1 else {
            target = (dice(0...(stage.width - Self.size)), dice(max(0, stage.ground - 14)...(stage.ground + 4)))
            return
        }
        let step = min(1, speed * dt / distance)
        position = (position.x + dx * step, position.y + dy * step)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        let wobble = (sin(flutter * 5) * 1.5).rounded()
        let y = (position.y + wobble).clamped(to: 0...(pet.stage.height - 4))
        return SceneSnapshot(
            pet: pet.item(pet.walkingSprite),
            prop: .init(sprite: Sprites.butterfly[Int(flutter * 8) % 2], x: position.x.rounded(), y: y.rounded())
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
