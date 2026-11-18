struct Pet {
    static let width = 16.0
    static let height = 12.0
    static let gravity = 180.0

    let stage: Stage
    var world = World()
    var sprites = Sprites.defaultPet
    var x: Double
    var facingRight = true
    var stride = 0.0
    var moving = false
    var pause = 0.0
    private(set) var feet: Double
    private var fallSpeed = 0.0
    private(set) var supported = true

    init(stage: Stage = .menuBar) {
        self.stage = stage
        x = min(14, stage.width - Self.width)
        feet = stage.height
    }

    var maxX: Double { stage.width - Self.width }
    var ground: Double { stage.ground }
    var top: Double { feet - Self.height }
    var lift: Double { stage.height - feet }
    var center: Double { x + Self.width / 2 }
    var isPaused: Bool { pause > 0 }
    var isAirborne: Bool { !supported }

    mutating func beginTick(_ dt: Double) {
        moving = false
        if pause > 0 { pause -= dt }
        applyGravity(dt)
    }

    mutating func walk(toward target: Double, speed: Double, dt: Double) {
        let delta = target - center
        guard abs(delta) > 0.5 else { return }
        facingRight = delta > 0
        let newX = (x + delta.clamped(to: -speed * dt ... speed * dt)).clamped(to: 0...maxX)
        stride += abs(newX - x)
        x = newX
        moving = true
    }

    mutating func jump(speed: Double = 55) {
        guard supported else { return }
        fallSpeed = -speed
        supported = false
    }

    mutating func leap(height: Double) {
        jump(speed: (2 * Self.gravity * max(height, 1)).squareRoot())
    }

    mutating func drop(atCenter center: Double) {
        x = (center - Self.width / 2).clamped(to: 0...maxX)
        feet = Self.height
        fallSpeed = 0
        supported = false
    }

    private mutating func applyGravity(_ dt: Double) {
        if supported {
            guard world.surface(at: feet, x: center, on: stage) == nil else { return }
            supported = false
            fallSpeed = 0
        }
        let oldFeet = feet
        feet += fallSpeed * dt + Self.gravity * dt * dt / 2
        fallSpeed += Self.gravity * dt
        guard fallSpeed > 0, let landing = world.landing(from: oldFeet, to: feet, x: center, on: stage) else { return }
        feet = landing
        fallSpeed = 0
        supported = true
    }

    var walkingSprite: Sprite {
        if isAirborne { return sprites.run[0] }
        return moving ? sprites.walk[Int(stride / 1.5) % 2] : sprites.walk[0]
    }

    var runningSprite: Sprite {
        if isAirborne { return sprites.run[0] }
        if isPaused { return sprites.run[1] }
        return moving ? sprites.run[Int(stride / 2) % 2] : sprites.walk[0]
    }

    func item(_ sprite: Sprite) -> SceneSnapshot.Item {
        .init(sprite: sprite, facingRight: facingRight, x: x.rounded(), y: max(0, top).rounded())
    }

    var restHeadX: Double { facingRight ? x + sprites.headOffset : x + Self.width - sprites.headOffset }
}
