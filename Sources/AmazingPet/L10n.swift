import Foundation
import AmazingPetCore

enum AppLanguage: String, CaseIterable {
    case system, english = "en", ukrainian = "uk"
}

enum L10n {
    static let appName = "Amazing Pet"

    static var language = AppLanguage.system {
        didSet { bundle = bundle(for: language) }
    }

    private static var bundle = bundle(for: .system)

    private static func bundle(for language: AppLanguage) -> Bundle? {
        switch language {
        case .system: .main
        case .english: nil
        case .ukrainian: Bundle.main.path(forResource: language.rawValue, ofType: "lproj").flatMap(Bundle.init(path:))
        }
    }

    static var customize: String { tr("menu.customize", "Customize pet…") }
    static var toyHeader: String { tr("menu.toy", "Toy") }
    static var autoMode: String { tr("menu.auto", "Auto (follows Mac load)") }
    static var indicators: String { tr("menu.indicators", "Smart indicators") }
    static var launchAtLogin: String { tr("menu.launchAtLogin", "Launch at login") }
    static var quit: String { tr("menu.quit", "Quit") }
    static var languageMenu: String { tr("menu.language", "Language") }
    static var roamMenu: String { tr("menu.roam", "Play on screen when I'm away") }
    static var roamOff: String { tr("menu.roam.off", "Off") }
    static var roamNow: String { tr("menu.roam.now", "Play now") }

    static func roamAfter(minutes: Int) -> String {
        String(format: tr("menu.roam.after", "After %d min"), minutes)
    }
    static var loginErrorTitle: String { tr("error.login", "Could not change launch at login") }

    static var defaultName: String { tr("pet.defaultName", "Pixel") }
    static var builderTitle: String { tr("builder.title", "Create your pet") }
    static var builderSubtitle: String { tr("builder.subtitle", "You can change it later in the menu") }
    static var nameLabel: String { tr("builder.name", "Name") }
    static var speciesLabel: String { tr("builder.species", "Animal") }
    static var coatLabel: String { tr("builder.coat", "Color") }
    static var eyesLabel: String { tr("builder.eyes", "Eyes") }
    static var randomButton: String { tr("builder.random", "Random") }
    static var doneButton: String { tr("builder.done", "Let's play!") }

    static func title(_ activity: Activity) -> String {
        switch activity {
        case .sleep: tr("toy.sleep", "Nap")
        case .yarn: tr("toy.yarn", "Yarn ball")
        case .mouse: tr("toy.mouse", "Toy mouse")
        case .laser: tr("toy.laser", "Laser pointer")
        case .zoomies: tr("toy.zoomies", "Zoomies")
        case .butterfly: tr("toy.butterfly", "Butterfly")
        case .explore: tr("toy.explore", "Exploring windows")
        case .peekaboo: tr("toy.peekaboo", "Hide and seek")
        case .cursor: tr("toy.cursor", "Cursor hunt")
        case .perch: tr("toy.perch", "Window nap")
        case .climb: tr("toy.climb", "Window climbing")
        case .ledge: tr("toy.ledge", "Window ledge")
        case .knock: tr("toy.knock", "Mischief")
        case .overheated: tr("alert.overheated.title", "Overheating")
        case .memoryTight: tr("alert.memoryTight.title", "Memory is tight")
        case .memoryFull: tr("alert.memoryFull.title", "Memory full")
        case .hungry: tr("alert.hungry.title", "Low battery")
        }
    }

    static func status(_ activity: Activity, name: String) -> String {
        let format = switch activity {
        case .sleep: tr("status.sleep", "%@ is napping 💤")
        case .yarn: tr("status.yarn", "%@ is chasing the yarn ball 🧶")
        case .mouse: tr("status.mouse", "%@ is hunting the toy mouse 🐭")
        case .laser: tr("status.laser", "%@ is catching the laser dot 🔴")
        case .zoomies: tr("status.zoomies", "%@ has the zoomies 💨")
        case .butterfly: tr("status.butterfly", "%@ is chasing a butterfly 🦋")
        case .explore: tr("status.explore", "%@ is exploring your windows 🧗")
        case .peekaboo: tr("status.peekaboo", "%@ is hiding behind a window 🙈")
        case .cursor: tr("status.cursor", "%@ is hunting your cursor 🖱")
        case .perch: tr("status.perch", "%@ is napping on a window 😴")
        case .climb: tr("status.climb", "%@ is climbing a window and sliding down 🧗")
        case .ledge: tr("status.ledge", "%@ is sitting on the edge of a window 🪟")
        case .knock: tr("status.knock", "%@ is knocking a flower pot off a window 🪴")
        case .overheated: tr("status.overheated", "%@ is too hot! Your Mac is overheating 🌡")
        case .memoryTight: tr("status.memoryTight", "%@ is hiding at home: memory is getting tight 🏠")
        case .memoryFull: tr("status.memoryFull", "%@ barely fits at home: memory is full 🏠")
        case .hungry: tr("status.hungry", "%@ is hungry: battery is low 🐟")
        }
        return String(format: format, name)
    }

    static func title(_ language: AppLanguage) -> String {
        switch language {
        case .system: tr("language.system", "System default")
        case .english: "English"
        case .ukrainian: "Українська"
        }
    }

    static func stroke(_ name: String) -> String {
        String(format: tr("menu.stroke", "Pet %@"), name)
    }

    static func title(_ species: Species) -> String {
        switch species {
        case .cat: tr("species.cat", "Cat")
        case .dog: tr("species.dog", "Dog")
        case .fox: tr("species.fox", "Fox")
        case .rabbit: tr("species.rabbit", "Rabbit")
        case .hamster: tr("species.hamster", "Hamster")
        case .bird: tr("species.bird", "Bird")
        case .fish: tr("species.fish", "Fish")
        case .turtle: tr("species.turtle", "Turtle")
        }
    }

    static func title(_ coat: Coat) -> String {
        switch coat {
        case .ginger: tr("coat.ginger", "Ginger")
        case .golden: tr("coat.golden", "Golden")
        case .brown: tr("coat.brown", "Brown")
        case .gray: tr("coat.gray", "Gray")
        case .black: tr("coat.black", "Black")
        case .white: tr("coat.white", "White")
        case .siamese: tr("coat.siamese", "Siamese")
        case .calico: tr("coat.calico", "Calico")
        case .spotted: tr("coat.spotted", "Spotted")
        case .blue: tr("coat.blue", "Blue")
        case .yellow: tr("coat.yellow", "Yellow")
        case .green: tr("coat.green", "Green")
        case .red: tr("coat.red", "Red")
        }
    }

    static func title(_ eyes: EyeColor) -> String {
        switch eyes {
        case .dark: tr("eyes.dark", "Dark")
        case .amber: tr("eyes.amber", "Amber")
        case .green: tr("eyes.green", "Green")
        case .blue: tr("eyes.blue", "Blue")
        }
    }

    static func metrics(_ status: SystemStatus) -> String {
        var parts = [
            String(format: tr("metrics.cpu", "CPU %d%%"), percent(status.cpu)),
            String(format: tr("metrics.memory", "Memory %d%%"), percent(status.memoryUsage)),
        ]
        if let battery = status.battery {
            parts.append(String(format: tr("metrics.battery", "Battery %d%%"), percent(battery.level)))
        }
        return parts.joined(separator: " · ")
    }

    private static func percent(_ value: Double) -> Int { Int((value * 100).rounded()) }

    private static func tr(_ key: String, _ english: String) -> String {
        bundle?.localizedString(forKey: key, value: english, table: nil) ?? english
    }
}
