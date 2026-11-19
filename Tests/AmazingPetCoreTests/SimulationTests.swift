import Testing
@testable import AmazingPetCore

struct SimulationTests {
    private func run(_ simulation: PetSimulation, seconds: Double, dt: Double = 0.05, check: (SceneSnapshot) -> Void = { _ in }) {
        for _ in 0..<Int(seconds / dt) {
            simulation.step(dt)
            check(simulation.snapshot())
        }
    }

    private func isOnStage(_ item: SceneSnapshot.Item) -> Bool {
        item.x >= 0 && item.x + Double(item.sprite.width) <= Stage.menuBar.width
    }

    @Test(arguments: Activity.allCases, Species.allCases)
    func everythingStaysOnStage(activity: Activity, species: Species) {
        let simulation = PetSimulation(activity: activity, look: PetLook(species: species), dice: Dice(seed: 42))
        simulation.speed = 2.2
        run(simulation, seconds: 60) { scene in
            #expect(isOnStage(scene.pet))
            if let prop = scene.prop { #expect(isOnStage(prop)) }
            #expect(scene.effects.allSatisfy(isOnStage))
        }
    }

    @Test(arguments: Activity.toys.filter { $0 != .sleep })
    func petChasesToys(activity: Activity) {
        let simulation = PetSimulation(activity: activity, dice: Dice(seed: 1))
        var positions = Set<Double>()
        run(simulation, seconds: 20) { positions.insert($0.pet.x) }
        #expect(positions.count > 5)
    }

    @Test func sleepingCatIsLoafWithZzz() {
        let simulation = PetSimulation(activity: .sleep, dice: Dice(seed: 1))
        run(simulation, seconds: 1)
        let scene = simulation.snapshot()
        #expect(scene.pet.sprite.rows == Species.cat.art.rest)
        #expect(scene.prop == nil)
        #expect(scene.effects.allSatisfy { $0.sprite === Sprites.zzz })
        #expect(scene.effects.count == 2)
    }

    @Test(arguments: [
        (Activity.overheated, Sprites.thermometer[0]), (.memoryTight, Sprites.house), (.memoryFull, Sprites.house),
        (.hungry, Sprites.bowl),
    ])
    func alertsShowTheirProp(activity: Activity, prop: Sprite) {
        let simulation = PetSimulation(activity: activity, dice: Dice(seed: 1))
        let scene = simulation.snapshot()
        #expect(scene.pet.sprite.rows == Species.cat.art.rest)
        #expect(scene.prop?.sprite === prop)
    }

    @Test(arguments: [Activity.memoryTight, .memoryFull])
    func fishHidesInAquarium(activity: Activity) {
        let simulation = PetSimulation(activity: activity, look: PetLook(species: .fish), dice: Dice(seed: 1))
        #expect(simulation.snapshot().prop?.sprite === Sprites.aquarium)
    }

    @Test func changingSpeciesMovesPetToItsHome() {
        let simulation = PetSimulation(activity: .memoryTight, dice: Dice(seed: 1))
        simulation.look = PetLook(species: .fish)
        #expect(simulation.snapshot().prop?.sprite === Sprites.aquarium)
    }

    @Test func homeSurroundsPetEvenAtStageEdge() {
        var pet = Pet()
        pet.x = pet.maxX
        let behavior = Activity.memoryTight.makeBehavior(for: &pet, dice: Dice(seed: 1))
        let scene = behavior.scene(pet, clock: 0)
        let prop = scene.prop!
        #expect(prop.x + (Double(prop.sprite.width) - Pet.width) / 2 == scene.pet.x)
    }

    @Test func onlyFullMemoryShakesTheHome() {
        var pet = Pet()
        let tight = Activity.memoryTight.makeBehavior(for: &pet, dice: Dice(seed: 1))
        let full = Activity.memoryFull.makeBehavior(for: &pet, dice: Dice(seed: 1))
        let positions = { (behavior: any Behavior) in Set([0, 0.25, 0.5, 0.75].map { behavior.scene(pet, clock: $0).prop!.x }) }
        #expect(positions(tight).count == 1)
        #expect(positions(full).count == 2)
        #expect(full.scene(pet, clock: 0).effects.allSatisfy { $0.sprite === Sprites.exclamation })
        #expect(tight.scene(pet, clock: 0).effects.allSatisfy { $0.sprite === Sprites.sweat })
    }

    @Test func alertPropDoesNotOverlapCatAtStageEdge() {
        var pet = Pet()
        pet.x = pet.maxX
        pet.facingRight = true
        let behavior = Activity.hungry.makeBehavior(for: &pet, dice: Dice(seed: 1))
        let prop = behavior.scene(pet, clock: 0).prop!
        #expect(!pet.facingRight)
        #expect(prop.x + Double(prop.sprite.width) <= pet.x)
    }

    @Test func pettingShowsHeartsThenResumes() {
        let simulation = PetSimulation(activity: .laser, dice: Dice(seed: 1))
        simulation.stroke()
        run(simulation, seconds: 1)
        let scene = simulation.snapshot()
        #expect(simulation.isPurring)
        #expect(scene.pet.sprite.rows == Species.cat.art.rest)
        #expect(scene.prop == nil)
        #expect(scene.effects.allSatisfy { $0.sprite === Sprites.heart })

        run(simulation, seconds: PetSimulation.purrDuration)
        #expect(!simulation.isPurring)
        #expect(simulation.snapshot().prop != nil)
    }

    @Test func settingSameActivityKeepsState() {
        let simulation = PetSimulation(activity: .yarn, dice: Dice(seed: 3))
        run(simulation, seconds: 5)
        let before = simulation.snapshot()
        simulation.setActivity(.yarn)
        #expect(simulation.snapshot().prop?.x == before.prop?.x)
    }

    @Test func changingActivitySwapsProp() {
        let simulation = PetSimulation(activity: .yarn, dice: Dice(seed: 3))
        simulation.setActivity(.mouse)
        #expect(simulation.activity == .mouse)
        #expect(Sprites.toyMouse.contains { $0 === simulation.snapshot().prop?.sprite })
    }

    @Test func yarnGetsKickedWhenCatArrives() {
        var pet = Pet()
        var yarn = YarnBehavior(pet: pet, dice: Dice(seed: 5))
        let start = yarn.ball
        for _ in 0..<200 {
            pet.beginTick(0.05)
            yarn.step(&pet, dt: 0.05, speed: 1)
        }
        #expect(yarn.ball != start)
    }

    @Test func mouseFleesFromCat() {
        var pet = Pet()
        var mouse = MouseBehavior(pet: pet, dice: Dice(seed: 9))
        pet.x = mouse.mouse - Pet.width / 2
        let start = mouse.mouse
        for _ in 0..<10 { mouse.step(&pet, dt: 0.05, speed: 1) }
        #expect(abs(mouse.mouse - start) > 3)
    }
}

struct PetTests {
    @Test func walkMovesTowardTargetWithinSpeed() {
        var pet = Pet()
        pet.walk(toward: 40, speed: 10, dt: 0.1)
        #expect(pet.x == 15)
        #expect(pet.facingRight)
        #expect(pet.moving)
    }

    @Test func walkTurnsAndClampsAtEdge() {
        var pet = Pet()
        pet.x = 0.5
        pet.walk(toward: -10, speed: 100, dt: 1)
        #expect(pet.x == 0)
        #expect(!pet.facingRight)
    }

    @Test func walkIgnoresTinyDistances() {
        var pet = Pet()
        pet.walk(toward: pet.center + 0.2, speed: 10, dt: 1)
        #expect(!pet.moving)
    }

    @Test func pauseCountsDown() {
        var pet = Pet()
        pet.pause = 0.1
        #expect(pet.isPaused)
        #expect(pet.runningSprite === Sprites.defaultPet.run[1])
        pet.beginTick(0.2)
        #expect(!pet.isPaused)
    }
}

struct DiceTests {
    @Test func sameSeedGivesSameSequence() {
        let a = Dice(seed: 11), b = Dice(seed: 11)
        #expect((0..<5).map { _ in a(0...1) } == (0..<5).map { _ in b(0...1) })
    }

    @Test func valuesStayInRange() {
        let dice = Dice(seed: 2)
        #expect((0..<1000).map { _ in dice(3...7) }.allSatisfy { (3...7).contains($0) })
    }
}
