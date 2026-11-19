import AppKit
import ApplicationServices

enum Permission: CaseIterable {
    case dockIcons, desktopIcons

    private static let finder = "com.apple.finder"
    private static let accessibilityPane = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    private static let automationPane = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"

    var isGranted: Bool {
        switch self {
        case .dockIcons: AXIsProcessTrusted()
        case .desktopIcons: Self.finderStatus(asking: false) == noErr
        }
    }

    func request() {
        switch self {
        case .dockIcons:
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            if !AXIsProcessTrustedWithOptions(options) { Self.open(Self.accessibilityPane) }
        case .desktopIcons:
            DispatchQueue.global(qos: .userInitiated).async {
                let status = Self.finderStatus(asking: true)
                if status != noErr { DispatchQueue.main.async { Self.open(Self.automationPane) } }
            }
        }
    }

    func requestAndWait() {
        switch self {
        case .dockIcons: request()
        case .desktopIcons: if Self.finderStatus(asking: true) != noErr { Self.open(Self.automationPane) }
        }
    }

    private static func finderStatus(asking: Bool) -> OSStatus {
        let target = NSAppleEventDescriptor(bundleIdentifier: finder)
        guard let descriptor = target.aeDesc else { return OSStatus(procNotFound) }
        return AEDeterminePermissionToAutomateTarget(descriptor, typeWildCard, typeWildCard, asking)
    }

    private static func open(_ pane: String) {
        if let url = URL(string: pane) { NSWorkspace.shared.open(url) }
    }
}
