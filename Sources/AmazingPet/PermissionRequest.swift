import AppKit

final class PermissionRequest: NSObject, NSApplicationDelegate {
    private static let settleSeconds = 2.0

    private let permission: Permission

    init(permission: Permission) {
        self.permission = permission
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !permission.isGranted else {
            NSApp.terminate(nil)
            return
        }
        permission.request {
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.settleSeconds) { NSApp.terminate(nil) }
        }
    }
}
