enum Cover: Equatable {
    case inFront(of: Box)
    case behind(Box)
}

struct Pet {
    static let width = 16.0
    static let height = 12.0
    static let climbWidth = 12.0
    static let gravity = Fall.gravity

    let stage: Stage
    var world = World()
    var sprites = Sprites.defaultPet
    var x: Double
    var facingRight = true
    var stride = 0.0
    var moving = false
    var pause = 0.0
    private var fall: Fall
    private(set) var clinging = false
    private(set) var footing: Platform
    var cover: Cover?

    init(stage: Stage = .menuBar) {
        self.stage = stage
        x = min(14, stage.width - Self.width)
        fall = Fall(feet: stage.height)
        footing = Platform(y: stage.height, minX: 0, maxX: stage.width)
    }

    var feet: Double { fall.feet }
    var supported: Bool { fall.supported && !clinging }

    var maxX: Double { stage.width - Self.width }
    var ground: Double { stage.ground }
    var top: Double { feet - Self.height }
    var lift: Double { stage.height - feet }
    var center: Double { x + Self.width / 2 }
    var isPaused: Bool { pause > 0 }
    var isAirborne: Bool { !fall.supported && !clinging }
    var lane: Platform { world.surface(under: (center, feet - 0.01), on: stage) }

    mutating func beginTick(_ dt: Double) {
        moving = false
        if pause > 0 { pause -= dt }
        if !clinging { fall.update(dt, x: center, world: world, on: stage) }
        if supported { footing = lane }
    }

    var hidingWindows: Int {
        let reference: (box: Box, behind: Bool)?
        switch cover {
        case .inFront(let box): reference = (box, false)
        case .behind(let box): reference = (box, true)
        case nil: reference = footing.window.map { ($0, false) }
        }
        guard let reference, let index = world.depth(of: reference.box) else { return world.occluders.count }
        return reference.behind ? index + 1 : index
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
        fall.launch(speed: speed)
    }

    mutating func leap(height: Double) {
        jump(speed: (2 * Self.gravity * max(height, 1)).squareRoot())
    }

    mutating func drop(atCenter center: Double) {
        x = (center - Self.width / 2).clamped(to: 0...maxX)
        clinging = false
        fall.release(from: Self.height)
    }

    mutating func cling(at feet: Double) {
        clinging = true
        fall.hold(at: feet)
    }

    mutating func letGo() {
        cover = nil
        guard clinging else { return }
        clinging = false
        fall.release(from: feet)
    }

    mutating func slide(down distance: Double) -> Bool {
        let target = feet + distance
        if let landing = world.landing(from: feet, to: target, x: center, on: stage) {
            stand(on: landing)
            return true
        }
        fall.hold(at: min(target, stage.height))
        return false
    }

    mutating func stand(on surface: Double) {
        clinging = false
        fall.land(on: surface)
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
