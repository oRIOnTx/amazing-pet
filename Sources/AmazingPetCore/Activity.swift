public enum Activity: String, CaseIterable {
    case sleep, yarn, mouse, laser
    case bone, fetch, tailChase, sniff, pounce, leaf, carrot, hop, binky, seeds, hamsterBall, wheel
    case peck, flutter, fly, bubbles, flakes, dart, lettuce, stroll, strawberry
    case zoomies, butterfly, explore, peekaboo, cursor, perch, climb, ledge, knock, hunt, peekOver, hang, gnaw
    case overheated, memoryTight, memoryFull, hungry

    public static let worldGames: [Activity] = [
        .explore, .peekaboo, .cursor, .climb, .ledge, .knock, .hunt, .peekOver, .hang, .gnaw, .zoomies, .butterfly,
    ]
    public static let allToys: [Activity] = Species.allCases.flatMap(\.toys)
    public static let alerts: [Activity] = [.overheated, .memoryTight, .memoryFull, .hungry]

    public static func roamGames(for species: Species) -> [Activity] { worldGames + species.toys }

    public var isAlert: Bool { Self.alerts.contains(self) }

    public var loadTier: Int? {
        Species.allCases.lazy.compactMap { $0.toys.firstIndex(of: self) }.first
    }

    public var fps: Double {
        switch self {
        case .sleep, .overheated, .memoryTight, .memoryFull, .hungry: 4
        case .bone, .carrot, .seeds, .peck, .lettuce, .sniff, .bubbles, .stroll, .flakes: 8
        case .explore, .peekaboo, .cursor, .perch, .climb, .ledge, .knock, .hunt, .peekOver, .hang, .gnaw: 15
        case .yarn, .strawberry: 10
        case .mouse, .butterfly, .leaf, .hop, .binky, .pounce, .flutter, .tailChase, .fly, .wheel: 12
        case .laser, .zoomies, .fetch, .dart, .hamsterBall: 15
        }
    }

    func makeBehavior(for pet: inout Pet, dice: Dice) -> any Behavior {
        switch self {
        case .sleep: return SleepBehavior()
        case .yarn: return YarnBehavior(pet: pet, dice: dice)
        case .mouse: return MouseBehavior(pet: pet, dice: dice)
        case .laser: return LaserBehavior(pet: pet, dice: dice)
        case .bone: return SnackBehavior(pet: pet, dice: dice, snack: .bone)
        case .fetch: return FetchBehavior(pet: pet, dice: dice)
        case .tailChase: return SpinBehavior(pet: pet, dice: dice)
        case .sniff: return WanderBehavior(pet: pet, dice: dice, wander: .sniff)
        case .pounce: return HopBehavior(pet: pet, dice: dice, hop: .pounce)
        case .leaf: return ButterflyBehavior(pet: pet, dice: dice, frames: Sprites.leaf)
        case .carrot: return SnackBehavior(pet: pet, dice: dice, snack: .carrot)
        case .hop: return HopBehavior(pet: pet, dice: dice, hop: .hop)
        case .binky: return HopBehavior(pet: pet, dice: dice, hop: .binky)
        case .seeds: return SnackBehavior(pet: pet, dice: dice, snack: .seeds)
        case .hamsterBall: return HamsterBallBehavior(pet: pet, dice: dice)
        case .wheel: return WheelBehavior(pet: &pet)
        case .peck: return SnackBehavior(pet: pet, dice: dice, snack: .grain)
        case .flutter: return HopBehavior(pet: pet, dice: dice, hop: .flutter)
        case .fly: return FlyBehavior(pet: pet, dice: dice)
        case .bubbles: return WanderBehavior(pet: pet, dice: dice, wander: .bubbles)
        case .flakes: return SnackBehavior(pet: pet, dice: dice, snack: .flakes)
        case .dart: return ZoomiesBehavior(pet: pet, dice: dice, leaps: false, pace: 60)
        case .lettuce: return SnackBehavior(pet: pet, dice: dice, snack: .lettuce)
        case .stroll: return WanderBehavior(pet: pet, dice: dice, wander: .stroll)
        case .strawberry: return SnackBehavior(pet: pet, dice: dice, snack: .strawberry)
        case .zoomies: return ZoomiesBehavior(pet: pet, dice: dice)
        case .butterfly: return ButterflyBehavior(pet: pet, dice: dice)
        case .explore: return ExploreBehavior(pet: pet, dice: dice)
        case .peekaboo: return PeekabooBehavior(pet: pet, dice: dice)
        case .cursor: return CursorBehavior(pet: pet, dice: dice)
        case .perch: return PerchBehavior(pet: pet, dice: dice)
        case .climb: return ClimbBehavior(pet: pet, dice: dice)
        case .ledge: return LedgeBehavior(pet: pet, dice: dice)
        case .knock: return KnockBehavior(pet: pet, dice: dice)
        case .hunt: return HuntBehavior(pet: pet, dice: dice)
        case .peekOver: return PeekOverBehavior(pet: pet, dice: dice)
        case .hang: return HangBehavior(pet: pet, dice: dice)
        case .gnaw: return GnawBehavior(pet: pet, dice: dice)
        case .overheated: return alert(.overheated, pet: &pet)
        case .memoryTight: return alert(.memoryTight(pet.sprites.home), pet: &pet)
        case .memoryFull: return alert(.memoryFull(pet.sprites.home), pet: &pet)
        case .hungry: return alert(.hungry, pet: &pet)
        }
    }

    private func alert(_ behavior: AlertBehavior, pet: inout Pet) -> AlertBehavior {
        behavior.prepare(&pet)
        return behavior
    }
}
