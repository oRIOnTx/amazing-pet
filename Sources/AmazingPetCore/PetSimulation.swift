public final class PetSimulation {
    public static let purrDuration = 2.5

    public private(set) var activity: Activity
    public var speed = 1.0
    public var world: World {
        get { pet.world }
        set { pet.world = newValue }
    }
    public var look: PetLook {
        didSet { if look != oldValue { dress(in: look) } }
    }

    private let dice: Dice
    private var pet: Pet
    private var behavior: any Behavior
    private var clock = 0.0
    private var purrTime = 0.0

    public init(stage: Stage = .menuBar, activity: Activity = .yarn, look: PetLook = PetLook(), dice: Dice = Dice()) {
        var pet = Pet(stage: stage)
        pet.sprites = PetSprites(look: look)
        self.activity = activity
        self.look = look
        self.dice = dice
        behavior = activity.makeBehavior(for: &pet, dice: dice)
        self.pet = pet
    }

    public var isPurring: Bool { purrTime > 0 }

    public var hidingWindows: Int { pet.hidingWindows }

    public func setActivity(_ new: Activity) {
        guard new != activity else { return }
        activity = new
        pet.pause = 0
        pet.letGo()
        behavior = new.makeBehavior(for: &pet, dice: dice)
    }

    private func dress(in look: PetLook) {
        pet.sprites = PetSprites(look: look)
        if activity.isAlert { behavior = activity.makeBehavior(for: &pet, dice: dice) }
    }

    public func stroke() { purrTime = Self.purrDuration }

    public func drop(atCenter x: Double) {
        pet.drop(atCenter: x)
    }

    public func step(_ dt: Double) {
        clock += dt
        guard purrTime <= 0 else {
            purrTime -= dt
            return
        }
        pet.beginTick(dt)
        behavior.step(&pet, dt: dt, speed: speed * pet.sprites.pace)
    }

    public func snapshot() -> SceneSnapshot {
        guard isPurring else { return behavior.scene(pet, clock: clock) }
        return SceneSnapshot(
            pet: pet.item(pet.sprites.rest),
            effects: Effects.floating(Sprites.heart, from: pet, clock: clock, rate: 0.9)
        )
    }
}
