import Testing
@testable import AmazingPetCore

struct SpeciesBehaviorTests {
    private let stage = Stage(width: 160, height: 40)

    private func scenes(_ activity: Activity, species: Species, seconds: Double, stage: Stage = .menuBar) -> [SceneSnapshot] {
        let simulation = PetSimulation(stage: stage, activity: activity, look: PetLook(species: species), dice: Dice(seed: 6))
        return (0..<Int(seconds / 0.05)).map { _ in
            simulation.step(0.05)
            return simulation.snapshot()
        }
    }

    @Test(arguments: [
        (Activity.bone, Species.dog, Sprites.bone), (.carrot, .rabbit, Sprites.carrot), (.seeds, .hamster, Sprites.seeds),
        (.peck, .bird, Sprites.grain), (.flakes, .fish, Sprites.flakes), (.lettuce, .turtle, Sprites.lettuce),
        (.strawberry, .turtle, Sprites.strawberry),
    ])
    func snacksGetEatenBiteByBite(activity: Activity, species: Species, food: [Sprite]) {
        let props = scenes(activity, species: species, seconds: 40, stage: stage).compactMap(\.prop?.sprite)
        for stage in food { #expect(props.contains { $0 === stage }) }
    }

    @Test func foodFlakesSinkBeforeTheFishEats() {
        let ys = scenes(.flakes, species: .fish, seconds: 3, stage: stage).compactMap(\.prop?.y)
        #expect(ys.first! < ys.last!)
    }

    @Test func dogBringsTheBallBack() {
        let all = scenes(.fetch, species: .dog, seconds: 40, stage: stage)
        let carried = all.filter { scene in
            guard let ball = scene.prop else { return false }
            return ball.y < stage.height - FetchBehavior.size && abs(ball.x - scene.pet.x - 6) < 10
        }
        let far = all.compactMap(\.prop).map(\.x)
        #expect(!carried.isEmpty)
        #expect(far.max()! - far.min()! > 30)
    }

    @Test func dogChasesItsTailThenGetsDizzy() {
        let all = scenes(.tailChase, species: .dog, seconds: 8)
        let turns = zip(all, all.dropFirst()).filter { $0.pet.facingRight != $1.pet.facingRight }.count
        #expect(turns > 10)
        #expect(all.contains { $0.effects.contains { $0.sprite === Sprites.star } })
    }

    @Test(arguments: [(Activity.pounce, Species.fox), (.hop, .rabbit), (.binky, .rabbit), (.flutter, .bird)])
    func hoppersLeaveTheGroundAndMove(activity: Activity, species: Species) {
        let all = scenes(activity, species: species, seconds: 15, stage: stage)
        let ground = stage.height - Pet.height
        #expect(all.contains { $0.pet.y < ground })
        #expect(Set(all.map(\.pet.x)).count > 5)
        #expect(all.contains { !$0.effects.isEmpty })
    }

    @Test func binkyTwistsInTheAir() {
        let all = scenes(.binky, species: .rabbit, seconds: 15, stage: stage)
        let ground = stage.height - Pet.height
        let airborneTurns = zip(all, all.dropFirst()).filter { $0.pet.y < ground && $1.pet.y < ground && $0.pet.facingRight != $1.pet.facingRight }
        #expect(!airborneTurns.isEmpty)
    }

    @Test func birdFliesAboveTheGround() {
        let tall = Stage(width: 160, height: 80)
        let all = scenes(.fly, species: .bird, seconds: 20, stage: tall)
        #expect(all.contains { $0.pet.y < tall.height - Pet.height - 10 })
        #expect(Set(all.map(\.pet.x)).count > 10)
    }

    @Test func hamsterRunsInPlaceInsideTheWheel() {
        let all = scenes(.wheel, species: .hamster, seconds: 4)
        #expect(Set(all.map(\.pet.x)).count == 1)
        #expect(Set(all.map { ObjectIdentifier($0.prop!.sprite) }).count == 2)
        #expect(all.allSatisfy { $0.prop!.x == $0.pet.x - 1 })
    }

    @Test func hamsterBallRollsWithTheHamster() {
        let all = scenes(.hamsterBall, species: .hamster, seconds: 10, stage: stage)
        #expect(Set(all.map(\.pet.x)).count > 10)
        #expect(all.allSatisfy { $0.prop?.sprite === Sprites.hamsterBall && abs($0.prop!.x - $0.pet.x) <= 1 })
    }

    @Test(arguments: [(Activity.sniff, Species.fox, Sprites.sniff), (.bubbles, .fish, Sprites.bubble)])
    func wanderersPauseWithTheirEffect(activity: Activity, species: Species, effect: Sprite) {
        let all = scenes(activity, species: species, seconds: 20, stage: stage)
        #expect(all.contains { $0.effects.contains { $0.sprite === effect } })
        #expect(Set(all.map(\.pet.x)).count > 5)
    }

    @Test func foxChasesAFallingLeaf() {
        let props = scenes(.leaf, species: .fox, seconds: 5).compactMap(\.prop?.sprite)
        #expect(props.allSatisfy { sprite in Sprites.leaf.contains { $0 === sprite } })
    }
}
