struct Fall {
    static let gravity = 180.0

    private(set) var feet: Double
    private(set) var speed = 0.0
    private(set) var supported = true

    init(feet: Double) {
        self.feet = feet
    }

    mutating func launch(speed: Double) {
        guard supported else { return }
        self.speed = -speed
        supported = false
    }

    mutating func release(from feet: Double) {
        self.feet = feet
        speed = 0
        supported = false
    }

    mutating func hold(at feet: Double) {
        self.feet = feet
        speed = 0
        supported = false
    }

    mutating func land(on feet: Double) {
        self.feet = feet
        speed = 0
        supported = true
    }

    mutating func update(_ dt: Double, x: Double, world: World, on stage: Stage) {
        if supported {
            guard world.surface(at: feet, x: x, on: stage) == nil else { return }
            supported = false
            speed = 0
        }
        let oldFeet = feet
        feet += speed * dt + Self.gravity * dt * dt / 2
        speed += Self.gravity * dt
        guard speed > 0, let landing = world.landing(from: oldFeet, to: feet, x: x, on: stage) else { return }
        land(on: landing)
    }
}
