import AppKit

let arguments = CommandLine.arguments
L10n.language = Settings().language
let grants: [String: Permission] = ["--grant-dock-access": .dockIcons, "--grant-desktop-access": .desktopIcons]
if arguments.count >= 2, let permission = grants[arguments[1]] {
    permission.requestAndWait()
    exit(0)
}
if arguments.count >= 3, arguments[1].hasPrefix("--export") {
    let target = URL(fileURLWithPath: arguments[2])
    switch arguments[1] {
    case "--export-icon": try ImageExporter.exportIconset(to: target)
    case "--export-preview": try ImageExporter.exportPreview(to: target)
    case "--export-species": try ImageExporter.exportSpecies(to: target)
    case "--export-roam": try ImageExporter.exportRoam(to: target)
    case "--export-docs": try MainActor.assumeIsolated { try DocsExporter.export(to: target) }
    case "--export-builder": try MainActor.assumeIsolated { try ImageExporter.exportBuilder(to: target) }
    default: break
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
