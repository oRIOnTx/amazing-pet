import Foundation
import ServiceManagement

enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    static func enableOnFirstInstall(_ settings: Settings) {
        guard !settings.didSetUpLoginItem, isInstalled else { return }
        do {
            try setEnabled(true)
            settings.didSetUpLoginItem = true
        } catch {
            NSLog("AmazingPet: login item registration failed: \(error)")
        }
    }

    private static var isInstalled: Bool {
        let path = Bundle.main.bundlePath
        return path.hasPrefix("/Applications/") || path.hasPrefix(NSHomeDirectory() + "/Applications/")
    }
}
