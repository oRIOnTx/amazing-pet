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
        defer { pet.cover = pet.clinging ? wall.top.window.map { .inFront(of: $0) } : nil }
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

struct HuntBehavior: Behavior {
    enum Phase: Equatable { case searching, found, playing }
    static let size = 6.0

    private let dice: Dice
    private var fallback: ExploreBehavior
    private(set) var phase = Phase.searching
    private(set) var finds = 0
    private var route: [Goal] = []
    private var sniffing = 0.0
    private var timer = 0.0
    private var toy = 0.0
    private var fall = Fall(feet: 0)
    private var velocity = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        fallback = ExploreBehavior(pet: pet, dice: dice)
        hide(pet)
    }

    private var center: Double { toy + Self.size / 2 }

    private mutating func hide(_ pet: Pet) {
        let spots = pet.world.hidingSpots(on: pet.stage).filter { $0.width >= Pet.width + 4 }
        route = (0..<min(3, spots.count)).compactMap { _ in pick(spots, dice: dice) }.map { Goal(surface: $0.y, x: $0.randomCenter(dice)) }
        phase = .searching
        guard let hidden = route.last else { return }
        toy = hidden.x - Self.size / 2
        fall = Fall(feet: hidden.surface)
        velocity = 0
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard !route.isEmpty || phase != .searching else {
            hide(pet)
            fallback.step(&pet, dt: dt, speed: speed)
            return
        }
        roll(dt, pet: pet)
        switch phase {
        case .searching:
            if sniffing > 0 {
                sniffing -= dt
                guard sniffing <= 0 else { return }
                route.removeFirst()
                if route.isEmpty { reveal(&pet) }
                return
            }
            if Navigator.step(&pet, to: route[0], speed: 18 * speed * pet.stage.travelBoost, dt: dt) {
                sniffing = route.count == 1 ? 0.8 : dice(1.2...2)
            }
        case .found:
            timer -= dt
            if timer <= 0 { phase = .playing; timer = dice(10...14) }
        case .playing:
            timer -= dt
            if timer <= 0 {
                hide(pet)
                return
            }
            chase(&pet, speed: speed, dt: dt)
        }
    }

    private mutating func reveal(_ pet: inout Pet) {
        finds += 1
        phase = .found
        timer = 1
        let world = pet.world
        let covering = world.occluders.first { $0.overlaps(x: toy...(toy + Self.size), y: (fall.feet - Self.size)...fall.feet) }
        let target: Double
        if let covering {
            let left = covering.minX - 10, right = covering.maxX + 10
            target = abs(left - center) < abs(right - center) && left > 0 ? left : right
        } else {
            target = center
        }
        let clamped = target.clamped(to: Self.size...(pet.stage.width - Self.size))
        velocity = (clamped - center) / 0.9
        fall.launch(speed: 45)
        pet.facingRight = velocity >= 0
    }

    private mutating func chase(_ pet: inout Pet, speed: Double, dt: Double) {
        guard !pet.isPaused else { return }
        let sameLane = fall.supported && !pet.isAirborne && abs(pet.feet - fall.feet) < 0.01
        let distance = center - pet.center
        if sameLane && abs(distance) < 11 {
            guard velocity == 0 else { return }
            pet.facingRight = distance > 0
            velocity = (distance > 0 ? 1 : -1) * dice(18...32) * pet.stage.travelBoost
            pet.pause = dice(0.3...0.8)
        } else {
            let surface = pet.world.surface(under: (center, fall.feet - 0.01), on: pet.stage)
            _ = Navigator.step(&pet, to: Goal(surface: surface.y, x: center), speed: 20 * speed * pet.stage.travelBoost, dt: dt)
        }
    }

    private mutating func roll(_ dt: Double, pet: Pet) {
        guard phase != .searching else { return }
        toy += velocity * dt
        let maxX = pet.stage.width - Self.size
        if toy < 0 || toy > maxX {
            toy = toy.clamped(to: 0...maxX)
            velocity = -velocity * 0.5
        }
        fall.update(dt, x: center, world: pet.world, on: pet.stage)
        guard fall.supported else { return }
        velocity *= pow(0.3, dt)
        if abs(velocity) < 1 { velocity = 0 }
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        guard !route.isEmpty || phase != .searching else { return fallback.scene(pet, clock: clock) }
        let favorite = pet.sprites.favorite
        let prop = SceneSnapshot.Item(
            sprite: favorite, x: (center - Double(favorite.width) / 2).rounded(),
            y: (fall.feet - Double(favorite.height)).rounded()
        )
        let effects: [SceneSnapshot.Item] = switch phase {
        case .searching where sniffing > 0: Effects.blinking(Sprites.question, over: pet, clock: clock)
        case .found: Effects.blinking(Sprites.exclamation, over: pet, clock: clock)
        default: []
        }
        let sprite = sniffing > 0 ? pet.sprites.walk[0] : pet.runningSprite
        return SceneSnapshot(pet: pet.item(sprite), prop: prop, effects: effects)
    }
}

struct PeekOverBehavior: Behavior {
    enum Phase: Equatable { case approaching, ducked, peeking }
    static let peekDepth = 6.0
    static let hideDepth = Pet.height + 2

    private let dice: Dice
    private var fallback: ExploreBehavior
    private(set) var top: Platform?
    private(set) var phase = Phase.approaching
    private(set) var peeks = 0
    private var spot = 0.0
    private var timer = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        fallback = ExploreBehavior(pet: pet, dice: dice)
        top = pick(pet.world.windowTops(on: pet.stage), dice: dice)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard let top, let window = top.window, pet.world.windowTops(on: pet.stage).contains(top) else {
            if pet.clinging { pet.letGo() }
            phase = .approaching
            self.top = pick(pet.world.windowTops(on: pet.stage), dice: dice)
            fallback.step(&pet, dt: dt, speed: speed)
            return
        }
        switch phase {
        case .approaching:
            guard Navigator.step(&pet, to: Goal(surface: top.y, x: top.randomCenter(dice)), speed: 16 * speed * pet.stage.travelBoost, dt: dt)
            else { return }
            duck(&pet, behind: window, top: top)
        case .ducked:
            let arrived = abs(pet.center - spot) < 1
            pet.walk(toward: spot, speed: 20 * speed, dt: dt)
            sink(&pet, toward: top.y + Self.hideDepth, dt: dt)
            timer -= dt
            guard arrived, timer <= 0 else { return }
            phase = .peeking
            timer = dice(1.2...2.2)
        case .peeking:
            sink(&pet, toward: top.y + Self.peekDepth, dt: dt)
            timer -= dt
            if timer < 0.6 && timer + dt >= 0.6 { pet.facingRight.toggle() }
            guard timer <= 0 else { return }
            peeks += 1
            if peeks.isMultiple(of: 4) {
                pet.stand(on: top.y)
                pet.cover = nil
                pet.leap(height: 4)
                pet.pause = dice(1...2)
                self.top = pick(pet.world.windowTops(on: pet.stage), dice: dice)
                phase = .approaching
            } else {
                duck(&pet, behind: window, top: top)
            }
        }
    }

    private mutating func duck(_ pet: inout Pet, behind window: Box, top: Platform) {
        pet.cover = .behind(window)
        pet.cling(at: pet.feet)
        spot = top.randomCenter(dice)
        phase = .ducked
        timer = dice(0.6...1.4)
    }

    private func sink(_ pet: inout Pet, toward feet: Double, dt: Double) {
        let step = 40 * dt
        pet.cling(at: pet.feet + (feet - pet.feet).clamped(to: -step...step))
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        guard top != nil else { return fallback.scene(pet, clock: clock) }
        return SceneSnapshot(pet: pet.item(phase == .approaching ? pet.walkingSprite : pet.sprites.walk[0]))
    }
}

struct HangBehavior: Behavior {
    enum Phase: Equatable { case approaching, leaping, hanging, dropping }
    static let reach = 60.0

    private let dice: Dice
    private var fallback: ExploreBehavior
    private(set) var launch: Platform?
    private(set) var phase = Phase.approaching
    private(set) var swings = 0
    private var spot = 0.0
    private var target = 0.0
    private var timer = 0.0
    private var stride = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        fallback = ExploreBehavior(pet: pet, dice: dice)
        launch = pick(Self.launches(pet), dice: dice)
        spot = launch?.randomCenter(dice) ?? 0
    }

    static func launches(_ pet: Pet) -> [Platform] {
        pet.world.surfaces(on: pet.stage).filter { $0.y - Pet.height <= reach && $0.width >= Pet.width }
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard let launch else {
            self.launch = pick(Self.launches(pet), dice: dice)
            spot = self.launch?.randomCenter(dice) ?? 0
            fallback.step(&pet, dt: dt, speed: speed)
            return
        }
        switch phase {
        case .approaching:
            guard Navigator.step(&pet, to: Goal(surface: launch.y, x: spot), speed: 16 * speed * pet.stage.travelBoost, dt: dt)
            else { return }
            pet.leap(height: pet.feet - Pet.height + 1)
            phase = .leaping
        case .leaping:
            if pet.top <= 0 {
                pet.cling(at: Pet.height)
                phase = .hanging
                timer = dice(4...7)
                target = (pet.center + dice(-40...40)).clamped(to: (Pet.width / 2)...(pet.stage.width - Pet.width / 2))
            } else if !pet.isAirborne {
                phase = .approaching
            }
        case .hanging:
            let before = pet.x
            pet.walk(toward: target, speed: 10 * speed, dt: dt)
            stride += abs(pet.x - before)
            if abs(pet.center - target) < 1 {
                swings += 1
                target = (pet.center + dice(-40...40)).clamped(to: (Pet.width / 2)...(pet.stage.width - Pet.width / 2))
            }
            timer -= dt
            guard timer <= 0 else { return }
            pet.letGo()
            phase = .dropping
        case .dropping:
            guard !pet.isAirborne else { return }
            pet.pause = dice(1...2)
            self.launch = pick(Self.launches(pet), dice: dice)
            spot = self.launch?.randomCenter(dice) ?? 0
            phase = .approaching
        }
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        guard launch != nil || phase != .approaching else { return fallback.scene(pet, clock: clock) }
        guard phase == .hanging else { return SceneSnapshot(pet: pet.item(pet.walkingSprite)) }
        let sprite = pet.sprites.hang[Int(stride / 2) % 2]
        return SceneSnapshot(pet: .init(sprite: sprite, facingRight: pet.facingRight, x: pet.x.rounded(), y: 0))
    }
}

struct GnawBehavior: Behavior {
    static let room = 8.0

    private let dice: Dice
    private var fallback: ExploreBehavior
    private(set) var ledge: Ledge?
    private(set) var gnawing = false
    private(set) var crumbs: [(x: Double, fall: Fall)] = []
    private var timer = 0.0
    private var nextCrumb = 0.0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        fallback = ExploreBehavior(pet: pet, dice: dice)
        ledge = pick(pet.world.ledges(on: pet.stage, room: Self.room), dice: dice)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        for index in crumbs.indices { crumbs[index].fall.update(dt, x: crumbs[index].x, world: pet.world, on: pet.stage) }
        crumbs.removeAll { $0.fall.supported }
        guard let ledge, pet.world.ledges(on: pet.stage, room: Self.room).contains(ledge) else {
            gnawing = false
            ledge = pick(pet.world.ledges(on: pet.stage, room: Self.room), dice: dice)
            fallback.step(&pet, dt: dt, speed: speed)
            return
        }
        guard gnawing else {
            let goal = Goal(surface: ledge.top.y, x: ledge.edge - ledge.outward * (Pet.width / 2 - 2))
            guard Navigator.step(&pet, to: goal, speed: 16 * speed * pet.stage.travelBoost, dt: dt) else { return }
            pet.facingRight = ledge.right
            gnawing = true
            timer = dice(5...8)
            return
        }
        nextCrumb -= dt * speed
        if nextCrumb <= 0, crumbs.count < 2 {
            var fall = Fall(feet: ledge.top.y + 1)
            fall.release(from: ledge.top.y + 1)
            crumbs.append((ledge.edge + ledge.outward * dice(1...3), fall))
            nextCrumb = dice(0.4...0.9)
        }
        timer -= dt
        guard timer <= 0 else { return }
        gnawing = false
        self.ledge = pick(pet.world.ledges(on: pet.stage, room: Self.room), dice: dice)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        guard ledge != nil else { return fallback.scene(pet, clock: clock) }
        let effects = crumbs.map { SceneSnapshot.Item(sprite: Sprites.crumb, x: ($0.x - 1).rounded(), y: ($0.fall.feet - 2).rounded()) }
        guard gnawing else { return SceneSnapshot(pet: pet.item(pet.walkingSprite), effects: effects) }
        let sprite = Int(clock * 5) % 2 == 0 ? pet.sprites.rest : pet.sprites.walk[0]
        return SceneSnapshot(pet: pet.item(sprite), effects: effects)
    }
}
