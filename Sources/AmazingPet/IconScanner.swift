import AppKit
import ApplicationServices
import AmazingPetCore

enum IconScanner {
    private static let desktopIconSize: CGFloat = 64
    private static let desktopScript = NSAppleScript(source: "tell application \"Finder\" to get desktop position of every item of desktop")

    static func scan(overlay frame: NSRect, pixel: CGFloat) -> [Icon] {
        let mainHeight = NSScreen.screens.first?.frame.height ?? frame.maxY
        let toStage = { (rect: CGRect, onDock: Bool) -> Icon in
            let local = CGRect(x: rect.minX - frame.minX, y: mainHeight - rect.maxY - frame.minY, width: rect.width, height: rect.height)
            let box = Box(
                x: local.minX / pixel, y: (frame.height - local.maxY) / pixel,
                width: local.width / pixel, height: local.height / pixel
            )
            return Icon(box: box, onDock: onDock)
        }
        let dock = Permission.dockIcons.isGranted ? dockIconFrames() : []
        let desktop = Permission.desktopIcons.isGranted && desktopIconsShown ? desktopIconFrames() : []
        return dock.map { toStage($0, true) } + desktop.map { toStage($0, false) }
    }

    private static var desktopIconsShown: Bool {
        UserDefaults(suiteName: "com.apple.finder")?.object(forKey: "CreateDesktop") as? Bool ?? true
    }

    private static func dockIconFrames() -> [CGRect] {
        guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else { return [] }
        let app = AXUIElementCreateApplication(dock.processIdentifier)
        guard let list = children(of: app).first(where: { role(of: $0) == kAXListRole }) else { return [] }
        return children(of: list).compactMap(frame(of:))
    }

    private static func desktopIconFrames() -> [CGRect] {
        guard let result = desktopScript?.executeAndReturnError(nil), result.numberOfItems > 0 else { return [] }
        return (1...result.numberOfItems).compactMap { index in
            guard let point = result.atIndex(index), point.numberOfItems == 2,
                  let x = point.atIndex(1)?.doubleValue, let y = point.atIndex(2)?.doubleValue
            else { return nil }
            return CGRect(x: x - desktopIconSize / 2, y: y - desktopIconSize / 2, width: desktopIconSize, height: desktopIconSize)
        }
    }

    private static func children(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success else { return [] }
        return value as? [AXUIElement] ?? []
    }

    private static func role(of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value) == .success else { return nil }
        return value as? String
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        var position: CFTypeRef?
        var size: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size) == .success,
              let position, let size
        else { return nil }
        var point = CGPoint.zero
        var extent = CGSize.zero
        guard AXValueGetValue(position as! AXValue, .cgPoint, &point), AXValueGetValue(size as! AXValue, .cgSize, &extent)
        else { return nil }
        return CGRect(origin: point, size: extent)
    }
}
