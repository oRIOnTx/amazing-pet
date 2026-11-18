// swift-tools-version: 5.10
import Foundation
import PackageDescription

let commandLineToolsTestingPlugins = "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing"
let usesCommandLineToolsOnly = FileManager.default.fileExists(atPath: commandLineToolsTestingPlugins)
    && !FileManager.default.fileExists(atPath: "/Applications/Xcode.app")
let testSettings: [SwiftSetting] = usesCommandLineToolsOnly
    ? [.unsafeFlags(["-plugin-path", commandLineToolsTestingPlugins])]
    : []

let package = Package(
    name: "AmazingPet",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "AmazingPetCore", linkerSettings: [.linkedFramework("IOKit")]),
        .executableTarget(name: "AmazingPet", dependencies: ["AmazingPetCore"]),
        .testTarget(name: "AmazingPetCoreTests", dependencies: ["AmazingPetCore"], swiftSettings: testSettings),
    ]
)
