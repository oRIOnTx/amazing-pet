import Testing
@testable import AmazingPetCore

struct AwayPolicyTests {
    @Test func roamsOnlyWhenEnabledAndIdleLongEnough() {
        #expect(!AwayPolicy.shouldRoam(SystemStatus(idleSeconds: 9999), delayMinutes: 0))
        #expect(!AwayPolicy.shouldRoam(SystemStatus(idleSeconds: 179), delayMinutes: 3))
        #expect(AwayPolicy.shouldRoam(SystemStatus(idleSeconds: 180), delayMinutes: 3))
    }

    @Test func doesNotRoamOverVideoOrCalls() {
        let watching = SystemStatus(idleSeconds: 600, displaySleepBlocked: true)
        #expect(!AwayPolicy.shouldRoam(watching, delayMinutes: 1))
    }

    @Test func userReturnsOnInputAfterRoamStarted() {
        #expect(AwayPolicy.userReturned(idleSeconds: 0.1, roamingFor: 10))
        #expect(!AwayPolicy.userReturned(idleSeconds: 190, roamingFor: 10))
    }

    @Test func clickThatStartedPlayNowDoesNotEndIt() {
        #expect(!AwayPolicy.userReturned(idleSeconds: 0.3, roamingFor: 0))
        #expect(!AwayPolicy.userReturned(idleSeconds: 2.3, roamingFor: 2))
    }
}

struct RoamDirectorTests {
    @Test func startsWithExploring() {
        for seed in 0..<50 {
            #expect(RoamDirector(dice: Dice(seed: UInt64(seed))).current == .explore)
        }
    }

    @Test func keepsGameUntilItsTimeIsUp() {
        var director = RoamDirector(dice: Dice(seed: 1), now: 0)
        #expect(director.update(now: RoamDirector.gameLength.lowerBound - 1, idleSeconds: 60) == nil)
    }

    @Test func switchesToDifferentGameLater() {
        var director = RoamDirector(dice: Dice(seed: 1), now: 0)
        let first = director.current
        let next = director.update(now: RoamDirector.gameLength.upperBound, idleSeconds: 60)
        #expect(next != nil)
        #expect(next != first)
        #expect(Activity.roamGames(for: .cat).contains(director.current))
    }

    @Test func napsAfterLongAbsenceOnce() {
        var director = RoamDirector(dice: Dice(seed: 1), now: 0)
        #expect(director.update(now: 1, idleSeconds: RoamDirector.napAfterIdle) == .perch)
        #expect(director.update(now: 999, idleSeconds: RoamDirector.napAfterIdle + 999) == nil)
    }

    @Test func roamGamesAreNotMenuToysOrAlerts() {
        #expect(!Activity.worldGames.contains { $0.isAlert })
        #expect(Mode(rawValue: Activity.zoomies.rawValue) == .auto)
        #expect(Mode(rawValue: Activity.butterfly.rawValue) == .auto)
    }
}

struct RoamSimulationTests {
    private let stage = Stage(width: 300, height: 40)

    private func isInside(_ item: SceneSnapshot.Item) -> Bool {
        item.x >= 0 && item.x + Double(item.sprite.width) <= stage.width
            && item.y >= 0 && item.y + Double(item.sprite.height) <= stage.height
    }

    @Test(arguments: Activity.worldGames + Activity.allToys + [.sleep], Species.allCases)
    func everythingStaysInsideRoamStage(activity: Activity, species: Species) {
        let simulation = PetSimulation(stage: stage, activity: activity, look: PetLook(species: species), dice: Dice(seed: 8))
        for _ in 0..<1200 {
            simulation.step(0.05)
            let scene = simulation.snapshot()
            #expect(isInside(scene.pet))
            if let prop = scene.prop { #expect(isInside(prop)) }
            #expect(scene.effects.allSatisfy(isInside))
        }
    }

    @Test func petStandsOnGround() {
        let simulation = PetSimulation(stage: stage, activity: .sleep, dice: Dice(seed: 1))
        #expect(simulation.snapshot().pet.y == stage.height - Pet.height)
    }

    @Test func zoomiesCoverMostOfTheScreen() {
        let simulation = PetSimulation(stage: stage, activity: .zoomies, dice: Dice(seed: 2))
        var xs: [Double] = []
        for _ in 0..<1200 {
            simulation.step(0.05)
            xs.append(simulation.snapshot().pet.x)
        }
        #expect(xs.max()! - xs.min()! > stage.width / 2)
    }

    @Test func butterflyMakesPetJump() {
        let simulation = PetSimulation(stage: stage, activity: .butterfly, dice: Dice(seed: 5))
        var lowest = stage.height
        for _ in 0..<2400 {
            simulation.step(0.05)
            lowest = min(lowest, simulation.snapshot().pet.y)
        }
        #expect(lowest < stage.height - Pet.height)
    }

    @Test func yarnRollsFurtherOnWideStage() {
        var pet = Pet(stage: stage)
        var yarn = YarnBehavior(pet: pet, dice: Dice(seed: 5))
        var farthest = 0.0
        for _ in 0..<400 {
            pet.beginTick(0.05)
            yarn.step(&pet, dt: 0.05, speed: 1)
            farthest = max(farthest, abs(yarn.velocity))
        }
        #expect(farthest > 30)
    }
}

struct JumpTests {
    @Test func jumpRisesAndLands() {
        var pet = Pet(stage: Stage(width: 100, height: 40))
        pet.jump()
        var peak = 0.0
        for _ in 0..<40 {
            pet.beginTick(0.02)
            peak = max(peak, pet.lift)
        }
        #expect(peak > 5)
        for _ in 0..<100 { pet.beginTick(0.02) }
        #expect(!pet.isAirborne)
        #expect(pet.lift == 0)
    }

    @Test func cannotDoubleJump() {
        var pet = Pet(stage: Stage(width: 100, height: 40))
        pet.jump()
        pet.beginTick(0.1)
        let lift = pet.lift
        pet.jump()
        pet.beginTick(0)
        #expect(pet.lift == lift)
    }

    @Test func jumpNeverLeavesMenuBarCanvas() {
        var pet = Pet()
        pet.jump()
        pet.beginTick(0.1)
        #expect(pet.item(pet.runningSprite).y == 0)
    }
}
