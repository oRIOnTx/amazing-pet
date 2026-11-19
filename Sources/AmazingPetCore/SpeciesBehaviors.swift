import Foundation

extension Platform {
    func randomCenter(_ dice: Dice) -> Double {
        let half = Pet.width / 2
        guard width > Pet.width else { return (minX + maxX) / 2 }
        return dice((minX + half)...(maxX - half))
    }

    func clampedCenter(_ x: Double) -> Double {
        let half = Pet.width / 2
        guard width > Pet.width else { return (minX + maxX) / 2 }
        return x.clamped(to: (minX + half)...(maxX - half))
    }
}

struct Snack {
    enum Spawn { case near, far, falling }
    enum Pose { case chew, peck }

    let food: [Sprite]
    let speed: Double
    let spawn: Spawn
    let pose: Pose

    static let bone = Snack(food: Sprites.bone, speed: 14, spawn: .near, pose: .chew)
    static let carrot = Snack(food: Sprites.carrot, speed: 12, spawn: .near, pose: .chew)
    static let seeds = Snack(food: Sprites.seeds, speed: 12, spawn: .near, pose: .peck)
    static let grain = Snack(food: Sprites.grain, speed: 12, spawn: .near, pose: .peck)
    static let lettuce = Snack(food: Sprites.lettuce, speed: 10, spawn: .near, pose: .chew)
    static let strawberry = Snack(food: Sprites.strawberry, speed: 22, spawn: .far, pose: .chew)
    static let flakes = Snack(food: Sprites.flakes, speed: 14, spawn: .falling, pose: .peck)
}

struct SnackBehavior: Behavior {
    private let snack: Snack
    private let dice: Dice
    private var lane: Platform
    private(set) var food = (x: 0.0, y: 0.0)
    private(set) var bites = 0
    private(set) var meals = 0
    private(set) var eating = false
    private var biteTimer = 0.0

    init(pet: Pet, dice: Dice, snack: Snack) {
        self.snack = snack
        self.dice = dice
        lane = pet.lane
        serve(near: pet)
    }

    private var size: (width: Double, height: Double) { (Double(snack.food[0].width), Double(snack.food[0].height)) }
    private var restingY: Double { lane.y - size.height }
    private var center: Double { food.x + size.width / 2 }

    private mutating func serve(near pet: Pet) {
        lane = pet.lane
        let maxX = max(lane.minX, lane.maxX - size.width)
        let x: Double
        switch snack.spawn {
        case .near, .falling:
            let side = dice(0...1) < 0.5 ? -1.0 : 1.0
            x = pet.center + side * dice(14...24) - size.width / 2
        case .far:
            let reach = lane.width * 0.3
            x = pet.center < (lane.minX + lane.maxX) / 2
                ? dice(max(lane.minX, maxX - reach)...maxX)
                : dice(lane.minX...min(maxX, lane.minX + reach))
        }
        food = (x.clamped(to: lane.minX...maxX), snack.spawn == .falling ? 0 : restingY)
        bites = 0
        eating = false
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        if pet.world.surface(at: lane.y, x: center, on: pet.stage) == nil { serve(near: pet) }
        food.y = min(restingY, food.y + 8 * dt)
        if eating {
            biteTimer -= dt * speed
            guard biteTimer <= 0 else { return }
            biteTimer = dice(1.2...2.2)
            if bites + 1 < snack.food.count {
                bites += 1
            } else {
                meals += 1
                serve(near: pet)
                pet.pause = dice(0.5...1.5)
            }
            return
        }
        guard !pet.isPaused else { return }
        let side: Double = center >= pet.center ? 1 : -1
        let mouth = side > 0 ? food.x - Pet.width / 2 + 2 : food.x + size.width + Pet.width / 2 - 2
        let goal = Goal(surface: lane.y, x: lane.clampedCenter(mouth))
        let arrived = Navigator.step(&pet, to: goal, speed: snack.speed * speed * pet.stage.travelBoost, dt: dt)
        guard arrived, food.y >= restingY else { return }
        pet.facingRight = side > 0
        eating = true
        biteTimer = dice(1.2...2.2)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        let sprite: Sprite
        if eating {
            sprite = snack.pose == .chew || Int(clock * 4) % 2 == 0 ? pet.sprites.rest : pet.sprites.walk[0]
        } else {
            sprite = pet.walkingSprite
        }
        return SceneSnapshot(
            pet: pet.item(sprite),
            prop: .init(sprite: snack.food[bites], x: food.x.rounded(), y: food.y.rounded())
        )
    }
}

struct Wander {
    let speed: Double
    let pauses: ClosedRange<Double>
    let effect: Sprite?

    static let sniff = Wander(speed: 9, pauses: 1...2.5, effect: Sprites.sniff)
    static let bubbles = Wander(speed: 6, pauses: 1.5...3, effect: Sprites.bubble)
    static let stroll = Wander(speed: 8, pauses: 0.5...1.5, effect: nil)
}

struct WanderBehavior: Behavior {
    private let wander: Wander
    private let dice: Dice
    private(set) var target: Double

    init(pet: Pet, dice: Dice, wander: Wander) {
        self.wander = wander
        self.dice = dice
        target = pet.lane.randomCenter(dice)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        guard !pet.isPaused else { return }
        let lane = pet.lane
        let goal = Goal(surface: lane.y, x: lane.clampedCenter(target))
        guard Navigator.step(&pet, to: goal, speed: wander.speed * speed * pet.stage.travelBoost, dt: dt) else { return }
        pet.pause = dice(wander.pauses)
        target = lane.randomCenter(dice)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        guard pet.isPaused, let effect = wander.effect else { return SceneSnapshot(pet: pet.item(pet.walkingSprite)) }
        return SceneSnapshot(pet: pet.item(pet.sprites.walk[0]), effects: Effects.floating(effect, from: pet, clock: clock, rate: 0.7))
    }
}

struct Hop {
    let height: Double
    let distance: Double
    let pauses: ClosedRange<Double>
    let twist: Bool

    static let hop = Hop(height: 6, distance: 10, pauses: 0.3...0.9, twist: false)
    static let binky = Hop(height: 12, distance: 8, pauses: 0.2...0.6, twist: true)
    static let pounce = Hop(height: 16, distance: 18, pauses: 1.2...2.4, twist: false)
    static let flutter = Hop(height: 5, distance: 6, pauses: 0.2...0.7, twist: false)
}

struct HopBehavior: Behavior {
    private let hop: Hop
    private let dice: Dice
    private var target: Double
    private var landingAt: Double?
    private var direction = 1.0
    private var flight = 0.0
    private var airTime = 0.0
    private var twisted = false
    private var dustTime = 0.0
    private(set) var hops = 0

    init(pet: Pet, dice: Dice, hop: Hop) {
        self.hop = hop
        self.dice = dice
        target = pet.lane.randomCenter(dice)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        dustTime -= dt
        if pet.isAirborne {
            fly(&pet, dt: dt)
            return
        }
        if landingAt != nil {
            landingAt = nil
            twisted = false
            pet.pause = dice(hop.pauses) / speed
            dustTime = 0.4
        }
        guard !pet.isPaused else { return }
        let lane = pet.lane
        if abs(target - pet.center) < 2 { target = lane.randomCenter(dice) }
        direction = target > pet.center ? 1 : -1
        pet.facingRight = direction > 0
        landingAt = lane.clampedCenter(pet.center + direction * min(hop.distance, abs(target - pet.center)))
        airTime = 2 * (2 * hop.height / Pet.gravity).squareRoot()
        flight = 0
        hops += 1
        pet.leap(height: hop.height)
    }

    private mutating func fly(_ pet: inout Pet, dt: Double) {
        flight += dt
        if let landingAt { pet.walk(toward: landingAt, speed: hop.distance / airTime * 1.2, dt: dt) }
        if hop.twist && flight >= airTime / 2 { twisted = true }
        pet.facingRight = twisted ? direction < 0 : direction > 0
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        let sprite = pet.isAirborne ? pet.sprites.run[0] : pet.sprites.walk[0]
        let dust = SceneSnapshot.Item(sprite: Sprites.dust, x: (pet.x + 4).rounded(), y: pet.feet - 2)
        return SceneSnapshot(pet: pet.item(sprite), effects: dustTime > 0 ? [dust] : [])
    }
}

struct FetchBehavior: Behavior {
    enum Phase: Equatable { case chasing, carrying, waiting }
    static let size = 4.0
    static let patience = 12.0

    private let dice: Dice
    private var home: Goal
    private(set) var phase = Phase.waiting
    private(set) var ball: Double
    private(set) var fetched = 0
    private var fall: Fall
    private var velocity = 0.0
    private var timer = 0.6

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        let lane = pet.lane
        home = Goal(surface: lane.y, x: lane.clampedCenter(pet.center))
        ball = pet.center
        fall = Fall(feet: lane.y)
    }

    private var center: Double { ball + Self.size / 2 }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        if phase != .carrying { roll(dt, pet: pet) }
        timer -= dt
        switch phase {
        case .waiting:
            guard timer <= 0 else { return }
            throwBall(pet)
        case .chasing:
            let surface = pet.world.surface(under: (center, fall.feet - 0.01), on: pet.stage)
            let close = fall.supported && !pet.isAirborne && abs(pet.feet - fall.feet) < 0.01 && abs(center - pet.center) < 7
            if close || timer <= 0 {
                phase = .carrying
                timer = Self.patience
                return
            }
            _ = Navigator.step(&pet, to: Goal(surface: surface.y, x: center), speed: 30 * speed * pet.stage.travelBoost, dt: dt)
        case .carrying:
            let back = Navigator.step(&pet, to: home, speed: 20 * speed * pet.stage.travelBoost, dt: dt)
            guard back || timer <= 0 else { return }
            ball = (pet.facingRight ? pet.x + Pet.width : pet.x - Self.size).clamped(to: 0...(pet.stage.width - Self.size))
            fall = Fall(feet: pet.feet)
            velocity = 0
            fetched += 1
            phase = .waiting
            timer = dice(0.6...1.4)
        }
    }

    private mutating func throwBall(_ pet: Pet) {
        let lane = pet.world.surface(under: (home.x, home.surface - 0.01), on: pet.stage)
        let direction: Double = home.x < (lane.minX + lane.maxX) / 2 ? 1 : -1
        velocity = direction * dice(18...34) * pet.stage.travelBoost
        fall.launch(speed: 40)
        phase = .chasing
        timer = Self.patience
    }

    private mutating func roll(_ dt: Double, pet: Pet) {
        ball += velocity * dt
        let maxX = pet.stage.width - Self.size
        if ball < 0 || ball > maxX {
            ball = ball.clamped(to: 0...maxX)
            velocity = -velocity * 0.5
        }
        fall.update(dt, x: center, world: pet.world, on: pet.stage)
        guard fall.supported else { return }
        velocity *= pow(0.25, dt)
        if abs(velocity) < 1 { velocity = 0 }
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        let item: SceneSnapshot.Item
        if phase == .carrying {
            let x = (pet.facingRight ? pet.x + Pet.width - 3 : pet.x - 1).clamped(to: 0...(pet.stage.width - Self.size))
            item = .init(sprite: Sprites.ball, x: x.rounded(), y: max(0, pet.top) + 6)
        } else {
            item = .init(sprite: Sprites.ball, x: ball.rounded(), y: max(0, fall.feet - Self.size).rounded())
        }
        let sprite = phase == .waiting && !pet.moving ? pet.sprites.walk[0] : pet.runningSprite
        return SceneSnapshot(pet: pet.item(sprite), prop: item)
    }
}

struct SpinBehavior: Behavior {
    private let dice: Dice
    private var spot: Double
    private var spinTime: Double
    private var flipTimer = 0.0
    private var dizzyTime = 0.0
    private(set) var turns = 0

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        spot = pet.lane.clampedCenter(pet.center)
        spinTime = dice(3...5)
    }

    var isDizzy: Bool { dizzyTime > 0 }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        if isDizzy {
            dizzyTime -= dt
            if !isDizzy {
                spot = pet.lane.randomCenter(dice)
                spinTime = dice(3...5)
            }
            return
        }
        let lane = pet.lane
        if abs(spot - pet.center) > 1 {
            _ = Navigator.step(&pet, to: Goal(surface: lane.y, x: lane.clampedCenter(spot)), speed: 20 * speed, dt: dt)
            if !pet.moving { spot = pet.center }
            return
        }
        spinTime -= dt
        flipTimer -= dt * speed
        if flipTimer <= 0 {
            pet.facingRight.toggle()
            turns += 1
            flipTimer = 0.2
        }
        if spinTime <= 0 { dizzyTime = 1.6 }
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        if isDizzy {
            return SceneSnapshot(pet: pet.item(pet.sprites.rest), effects: Effects.blinking(Sprites.star, over: pet, clock: clock))
        }
        let sprite = pet.moving ? pet.walkingSprite : pet.sprites.run[Int(clock * 8) % 2]
        return SceneSnapshot(pet: pet.item(sprite))
    }
}

struct FlyBehavior: Behavior {
    private let dice: Dice
    private(set) var target: (x: Double, feet: Double)

    init(pet: Pet, dice: Dice) {
        self.dice = dice
        target = (pet.center, pet.feet)
        target = next(pet)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        let dx = target.x - pet.center
        let dy = target.feet - pet.feet
        let distance = (dx * dx + dy * dy).squareRoot()
        guard distance > 1 else {
            target = next(pet)
            return
        }
        let reach = min(distance, 30 * speed * pet.stage.travelBoost * dt)
        pet.walk(toward: target.x, speed: reach * abs(dx) / distance / dt, dt: dt)
        pet.cling(at: (pet.feet + dy / distance * reach).clamped(to: Pet.height...pet.stage.floor))
    }

    private func next(_ pet: Pet) -> (x: Double, feet: Double) {
        let surfaces = pet.world.surfaces(on: pet.stage)
        let lane = dice(0...1) < 0.6 ? pet.lane : surfaces[Int(dice(0...Double(surfaces.count - 1)).rounded())]
        let feet = (lane.y - dice(0...30)).clamped(to: Pet.height...lane.y)
        return (lane.randomCenter(dice), feet)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        SceneSnapshot(pet: pet.item(pet.sprites.run[Int(clock * 8) % 2]))
    }
}

struct HamsterBallBehavior: Behavior {
    private var zoomies: ZoomiesBehavior

    init(pet: Pet, dice: Dice) {
        zoomies = ZoomiesBehavior(pet: pet, dice: dice, leaps: false, pace: 30)
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        zoomies.step(&pet, dt: dt, speed: speed)
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        let ball = Sprites.hamsterBall
        let x = (pet.x - 1).clamped(to: 0...(pet.stage.width - Double(ball.width)))
        return SceneSnapshot(
            pet: pet.item(pet.walkingSprite),
            prop: .init(sprite: ball, x: x.rounded(), y: max(0, pet.top).rounded())
        )
    }
}

struct WheelBehavior: Behavior {
    private(set) var spin = 0.0

    init(pet: inout Pet) {
        let margin = (Double(Sprites.wheel[0].width) - Pet.width) / 2
        pet.x = pet.x.clamped(to: margin...(pet.stage.width - Pet.width - margin))
    }

    mutating func step(_ pet: inout Pet, dt: Double, speed: Double) {
        spin += dt * speed * 10
    }

    func scene(_ pet: Pet, clock: Double) -> SceneSnapshot {
        let wheel = Sprites.wheel[Int(spin / 2) % 2]
        let x = pet.x - (Double(wheel.width) - Pet.width) / 2
        return SceneSnapshot(
            pet: pet.item(pet.sprites.run[Int(spin) % 2]),
            prop: .init(sprite: wheel, x: x.rounded(), y: max(0, pet.top).rounded())
        )
    }
}
