import AppKit
import AmazingPetCore
import SwiftUI

final class PetBuilderWindow: NSObject, NSWindowDelegate {
    private let settings: Settings
    private let onLookChange: (PetLook) -> Void
    private var window: NSWindow?
    private var model: PetBuilderModel?

    init(settings: Settings, onLookChange: @escaping (PetLook) -> Void) {
        self.settings = settings
        self.onLookChange = onLookChange
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func reload() {
        guard let window, let model else { return }
        window.contentView = NSHostingView(rootView: PetBuilderView(model: model))
    }

    private func makeWindow() -> NSWindow {
        let model = PetBuilderModel(profile: settings.profile, onLookChange: onLookChange) { [weak self] in
            self?.window?.close()
        }
        self.model = model
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: PetBuilderView.size),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor(cgColor: PixelTheme.background)
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = NSHostingView(rootView: PetBuilderView(model: model))
        window.delegate = self
        window.center()
        return window
    }

    func windowWillClose(_ notification: Notification) {
        if let model { settings.profile = model.profile }
        settings.didCreatePet = true
        window = nil
        model = nil
    }
}
