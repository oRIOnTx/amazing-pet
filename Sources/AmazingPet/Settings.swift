import Foundation
import AmazingPetCore

struct Settings {
    private enum Key {
        static let mode = "mode"
        static let indicators = "indicatorsEnabled"
        static let language = "language"
        static let roamDelay = "roamDelayMinutes"
        static let didSetUpLoginItem = "didSetUpLoginItem"
        static let didCreatePet = "didCreatePet"
        static let name = "petName"
        static let species = "petSpecies"
        static let coat = "petCoat"
        static let eyes = "petEyes"
    }

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var mode: Mode {
        get { Mode(rawValue: defaults.string(forKey: Key.mode)) }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Key.mode) }
    }

    var indicatorsEnabled: Bool {
        get { defaults.object(forKey: Key.indicators) as? Bool ?? true }
        nonmutating set { defaults.set(newValue, forKey: Key.indicators) }
    }

    var language: AppLanguage {
        get { defaults.string(forKey: Key.language).flatMap(AppLanguage.init(rawValue:)) ?? .system }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Key.language) }
    }

    var roamDelayMinutes: Int {
        get { defaults.integer(forKey: Key.roamDelay) }
        nonmutating set { defaults.set(newValue, forKey: Key.roamDelay) }
    }

    var didSetUpLoginItem: Bool {
        get { defaults.bool(forKey: Key.didSetUpLoginItem) }
        nonmutating set { defaults.set(newValue, forKey: Key.didSetUpLoginItem) }
    }

    var didCreatePet: Bool {
        get { defaults.bool(forKey: Key.didCreatePet) }
        nonmutating set { defaults.set(newValue, forKey: Key.didCreatePet) }
    }

    var profile: PetProfile {
        get {
            let look = PetLook(
                species: defaults.string(forKey: Key.species).flatMap(Species.init(rawValue:)) ?? .cat,
                coat: defaults.string(forKey: Key.coat).flatMap(Coat.init(rawValue:)),
                eyes: defaults.string(forKey: Key.eyes).flatMap(EyeColor.init(rawValue:)) ?? .dark
            )
            return PetProfile(name: defaults.string(forKey: Key.name) ?? L10n.defaultName, look: look)
        }
        nonmutating set {
            defaults.set(newValue.name, forKey: Key.name)
            defaults.set(newValue.look.species.rawValue, forKey: Key.species)
            defaults.set(newValue.look.coat.rawValue, forKey: Key.coat)
            defaults.set(newValue.look.eyes.rawValue, forKey: Key.eyes)
        }
    }
}
