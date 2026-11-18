public enum Activity: String, CaseIterable {
    case sleep, yarn, mouse, laser, zoomies, butterfly, explore, peekaboo, cursor, perch, overheated, memoryFull, hungry

    public static let toys: [Activity] = [.sleep, .yarn, .mouse, .laser]
    public static let roamGames: [Activity] = [.explore, .peekaboo, .cursor, .zoomies, .butterfly, .yarn, .mouse, .laser]
    public static let alerts: [Activity] = [.overheated, .memoryFull, .hungry]

    public var isAlert: Bool { Self.alerts.contains(self) }

    public var fps: Double {
        switch self {
        case .sleep, .overheated, .memoryFull, .hungry: 4
        case .explore, .peekaboo, .cursor, .perch: 15
        case .yarn: 10
        case .mouse: 12
        case .butterfly: 12
        case .laser, .zoomies: 15
        }
    }

    func makeBehavior(for pet: inout Pet, dice: Dice) -> any Behavior {
        switch self {
        case .sleep: return SleepBehavior()
        case .yarn: return YarnBehavior(pet: pet, dice: dice)
        case .mouse: return MouseBehavior(pet: pet, dice: dice)
        case .laser: return LaserBehavior(pet: pet, dice: dice)
        case .zoomies: return ZoomiesBehavior(pet: pet, dice: dice)
        case .butterfly: return ButterflyBehavior(pet: pet, dice: dice)
        case .explore: return ExploreBehavior(pet: pet, dice: dice)
        case .peekaboo: return PeekabooBehavior(pet: pet, dice: dice)
        case .cursor: return CursorBehavior(pet: pet, dice: dice)
        case .perch: return PerchBehavior(pet: pet, dice: dice)
        case .overheated: return alert(.overheated, pet: &pet)
        case .memoryFull: return alert(.memoryFull, pet: &pet)
        case .hungry: return alert(.hungry, pet: &pet)
        }
    }

    private func alert(_ behavior: AlertBehavior, pet: inout Pet) -> AlertBehavior {
        behavior.prepare(&pet)
        return behavior
    }
}
