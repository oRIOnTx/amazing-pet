import Testing
@testable import AmazingPetCore

struct WorldTests {
    let stage = Stage(width: 300, height: 200)
    let window = Box(x: 100, y: 120, width: 80, height: 60)

    @Test func windowTopsBecomePlatformsAboveGround() {
        let surfaces = World(occluders: [window]).surfaces(on: stage)
        #expect(surfaces.contains(Platform(y: 120, minX: 100, maxX: 180)))
        #expect(surfaces.last == Platform(y: 200, minX: 0, maxX: 300))
    }

    @Test func windowsTouchingMenuBarHaveNoPlatform() {
        let tall = Box(x: 10, y: 5, width: 100, height: 100)
        #expect(World(occluders: [tall]).surfaces(on: stage).count == 1)
    }

    @Test func tinyAndMaximizedWindowsAreIgnored() {
        #expect(!World.isOccluder(Box(x: 0, y: 0, width: 20, height: 10), on: stage))
        #expect(!World.isOccluder(Box(x: 0, y: 0, width: 300, height: 190), on: stage))
        #expect(World.isOccluder(window, on: stage))
    }

    @Test func hidingSpotIsGroundBehindLowWindow() {
        let low = Box(x: 50, y: 150, width: 60, height: 50)
        let spots = World(occluders: [low]).hidingSpots(on: stage)
        #expect(spots == [Platform(y: 200, minX: 50, maxX: 110)])
    }

    @Test func windowDoesNotHideItsOwnTop() {
        #expect(World(occluders: [window]).hidingSpots(on: stage).allSatisfy { $0.y != window.minY })
    }

    @Test func landsOnFirstSurfaceWhileFalling() {
        let world = World(occluders: [window])
        #expect(world.landing(from: 100, to: 130, x: 140, on: stage) == 120)
        #expect(world.landing(from: 100, to: 130, x: 20, on: stage) == nil)
        #expect(world.landing(from: 125, to: 210, x: 140, on: stage) == 200)
    }

    @Test func highestPerchIsTopmostWindow() {
        let higher = Box(x: 200, y: 60, width: 60, height: 40)
        #expect(World(occluders: [window, higher]).highestPerch(on: stage).y == 60)
        #expect(World().highestPerch(on: stage).y == stage.height)
    }

    @Test func availableGamesDependOnWorld() {
        let empty = RoamDirector.availableGames(in: World(), on: stage)
        #expect(!empty.contains(.peekaboo))
        #expect(!empty.contains(.cursor))
        let rich = World(occluders: [Box(x: 50, y: 150, width: 60, height: 50)], cursor: (10, 10))
        #expect(RoamDirector.availableGames(in: rich, on: stage) == Activity.roamGames(for: .cat))
        #expect(RoamDirector.availableGames(in: rich, on: stage, species: .dog).contains(.fetch))
    }
}

struct PlatformPhysicsTests {
    let stage = Stage(width: 300, height: 200)
    let world = World(occluders: [Box(x: 100, y: 120, width: 80, height: 60)])

    private func settle(_ pet: inout Pet, seconds: Double = 3) {
        for _ in 0..<Int(seconds / 0.02) { pet.beginTick(0.02) }
    }

    @Test func droppedPetLandsOnWindowTop() {
        var pet = Pet(stage: stage)
        pet.world = world
        pet.drop(atCenter: 140)
        settle(&pet)
        #expect(pet.supported)
        #expect(pet.feet == 120)
    }

    @Test func walkingOffWindowEdgeFallsToGround() {
        var pet = Pet(stage: stage)
        pet.world = world
        pet.drop(atCenter: 140)
        settle(&pet)
        for _ in 0..<200 {
            pet.beginTick(0.02)
            pet.walk(toward: 290, speed: 30, dt: 0.02)
        }
        settle(&pet)
        #expect(pet.feet == stage.height)
    }

    @Test func petFallsWhenWindowCloses() {
        var pet = Pet(stage: stage)
        pet.world = world
        pet.drop(atCenter: 140)
        settle(&pet)
        pet.world = World()
        settle(&pet)
        #expect(pet.feet == stage.height)
    }

    @Test func navigatorClimbsOntoWindow() {
        var pet = Pet(stage: stage)
        pet.world = world
        let goal = Goal(surface: 120, x: 150)
        var arrived = false
        for _ in 0..<1500 where !arrived {
            pet.beginTick(0.02)
            arrived = Navigator.step(&pet, to: goal, speed: 16, dt: 0.02)
        }
        #expect(arrived)
        #expect(pet.feet == 120)
    }

    @Test func navigatorClimbsDownFromWindow() {
        var pet = Pet(stage: stage)
        pet.world = world
        pet.drop(atCenter: 140)
        settle(&pet)
        let goal = Goal(surface: 200, x: 150)
        var arrived = false
        for _ in 0..<1500 where !arrived {
            pet.beginTick(0.02)
            arrived = Navigator.step(&pet, to: goal, speed: 16, dt: 0.02)
        }
        #expect(arrived)
        #expect(pet.feet == 200)
    }
}

struct WorldGameTests {
    let stage = Stage(width: 300, height: 200)

    private func run(_ activity: Activity, world: World, seconds: Double, seed: UInt64 = 3) -> [SceneSnapshot] {
        let simulation = PetSimulation(stage: stage, activity: activity, dice: Dice(seed: seed))
        simulation.world = world
        return (0..<Int(seconds / 0.05)).map { _ in
            simulation.step(0.05)
            return simulation.snapshot()
        }
    }

    @Test func peekabooHidesAndPeeksOut() {
        let wall = Box(x: 120, y: 150, width: 60, height: 50)
        let scenes = run(.peekaboo, world: World(occluders: [wall]), seconds: 30)
        let hidden = scenes.contains { $0.pet.x >= wall.minX && $0.pet.x + Pet.width <= wall.maxX }
        let peeking = scenes.contains { !$0.effects.isEmpty }
        #expect(hidden)
        #expect(peeking)
    }

    @Test func cursorHuntPouncesNearCursor() {
        let cursor = (x: 220.0, y: 170.0)
        let scenes = run(.cursor, world: World(cursor: cursor), seconds: 25)
        let near = scenes.filter { abs($0.pet.x + Pet.width / 2 - cursor.x) < 16 }
        #expect(!near.isEmpty)
        #expect(near.contains { $0.pet.y < stage.height - Pet.height })
    }

    @Test func perchClimbsHighestWindowAndSleeps() {
        let windows = [Box(x: 40, y: 140, width: 70, height: 60), Box(x: 180, y: 90, width: 70, height: 60)]
        let last = run(.perch, world: World(occluders: windows), seconds: 40).last!
        #expect(last.pet.y == 90 - Pet.height)
        #expect(last.effects.allSatisfy { $0.sprite === Sprites.zzz })
    }

    @Test(arguments: [Activity.explore, .peekaboo, .cursor, .perch])
    func worldGamesStayOnScreen(activity: Activity) {
        let world = World(occluders: [Box(x: 40, y: 140, width: 70, height: 60), Box(x: 200, y: 60, width: 80, height: 70)], cursor: (150, 100))
        for scene in run(activity, world: world, seconds: 60) {
            #expect(scene.pet.x >= 0 && scene.pet.x + Pet.width <= stage.width)
            #expect(scene.pet.y >= 0 && scene.pet.y + Pet.height <= stage.height)
        }
    }
}

struct MemoryUsageTests {
    @Test func usageCountsAppWiredAndCompressedPages() {
        let pages = MemoryPages(appInternal: 600, purgeable: 100, wired: 200, compressed: 100)
        #expect(pages.usage(pageSize: 1, totalBytes: 1000) == 0.8)
    }

    @Test func usageIsClampedAndSafe() {
        #expect(MemoryPages(appInternal: 5000, purgeable: 0, wired: 0, compressed: 0).usage(pageSize: 1, totalBytes: 1000) == 1)
        #expect(MemoryPages(appInternal: 10, purgeable: 50, wired: 0, compressed: 0).usage(pageSize: 1, totalBytes: 1000) == 0)
        #expect(MemoryPages(appInternal: 1, purgeable: 0, wired: 0, compressed: 0).usage(pageSize: 1, totalBytes: 0) == 0)
    }
}

struct WindowPlayTests {
    let stage = Stage(width: 200, height: 110)
    let windows = [Box(x: 18, y: 52, width: 70, height: 58), Box(x: 118, y: 34, width: 62, height: 42)]

    private func simulation(_ activity: Activity, seed: UInt64 = 4) -> PetSimulation {
        let simulation = PetSimulation(stage: stage, activity: .explore, dice: Dice(seed: seed))
        simulation.world = World(occluders: windows)
        simulation.drop(atCenter: 150)
        for _ in 0..<20 { simulation.step(0.05) }
        simulation.setActivity(activity)
        return simulation
    }

    private func run(_ simulation: PetSimulation, seconds: Double) -> [SceneSnapshot] {
        (0..<Int(seconds / 0.05)).map { _ in
            simulation.step(0.05)
            return simulation.snapshot()
        }
    }

    @Test func toysAppearOnTheWindowThePetStandsOn() {
        let top = windows[1].minY
        for toy in [Activity.yarn, .mouse] {
            let scene = simulation(toy).snapshot()
            let prop = scene.prop!
            #expect(prop.y + Double(prop.sprite.height) == top)
        }
    }

    @Test func yarnRollsOffWindowAndPetFollows() {
        let scenes = run(simulation(.yarn), seconds: 30)
        #expect(scenes.contains { $0.prop!.y + YarnBehavior.size == stage.height })
        #expect(scenes.contains { $0.pet.y + Pet.height == stage.height })
    }

    @Test func climbsUpWindowSideAndSlidesDown() {
        let scenes = run(simulation(.climb), seconds: 40)
        let clinging = scenes.filter { $0.pet.sprite.width == Int(Pet.climbWidth) }
        #expect(!clinging.isEmpty)
        #expect(clinging.allSatisfy { scene in windows.contains { scene.pet.x + Pet.climbWidth == $0.minX || scene.pet.x == $0.maxX } })
        #expect(scenes.contains { scene in scene.pet.y + Pet.height == windows[0].minY })
    }

    @Test func sitsOnLedgeWithLegsDangling() {
        let scenes = run(simulation(.ledge), seconds: 20)
        let sitting = scenes.filter { $0.prop != nil }
        #expect(!sitting.isEmpty)
        for scene in sitting {
            let legs = scene.prop!
            #expect(windows.contains { legs.y == $0.minY && (legs.x == $0.maxX || legs.x + Double(legs.sprite.width) == $0.minX) })
        }
    }

    @Test func knocksPotOffWindow() {
        let scenes = run(simulation(.knock), seconds: 25)
        #expect(scenes.contains { scene in scene.prop?.sprite === Sprites.pot && windows.contains { scene.prop!.y + 6 == $0.minY } })
        #expect(scenes.contains { $0.prop?.sprite === Sprites.shards })
        #expect(scenes.contains { !$0.effects.isEmpty })
    }

    @Test func switchingGameLetsGoOfTheWall() {
        let simulation = simulation(.climb)
        let scenes = run(simulation, seconds: 40)
        guard let index = scenes.firstIndex(where: { $0.pet.sprite.width == Int(Pet.climbWidth) }) else {
            Issue.record("never climbed")
            return
        }
        let replay = self.simulation(.climb)
        _ = run(replay, seconds: Double(index + 1) * 0.05)
        replay.setActivity(.zoomies)
        let after = run(replay, seconds: 5)
        #expect(after.last!.pet.sprite.width == Int(Pet.width))
        #expect(after.contains { scene in scene.pet.y + Pet.height == stage.height || windows.contains { scene.pet.y + Pet.height == $0.minY } })
    }

    @Test func navigatorLeavesPlatformTouchingScreenEdge() {
        let platform = Platform(y: 50, minX: 0, maxX: 80)
        #expect(Navigator.exit(from: platform, toward: 5, on: stage) == 81)
        #expect(Navigator.exit(from: Platform(y: 50, minX: 0, maxX: 200), toward: 5, on: stage) == nil)
    }

    @Test func climbFramesAreTurnedUpright() {
        #expect(SpeciesArt.turnedUp(["ab", "cd", "ef"]) == ["bdf", "ace"])
        let climb = PetSprites().climb[0]
        #expect(climb.width == Int(Pet.climbWidth))
        #expect(climb.height == Int(Pet.width))
    }
}
