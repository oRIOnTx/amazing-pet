import AmazingPetCore
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum DocsExporter {
    private static let gifFPS = 10.0
    private static let caption = Palette.color(0xF6EEDC)

    @MainActor
    static func export(to directory: URL) throws {
        L10n.language = .english
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try ImageExporter.writePNG(banner(), to: directory.appendingPathComponent("banner.png"))
        try writeGIF(menuBarDemo(), to: directory.appendingPathComponent("menubar.gif"))
        try writeGIF(roamDemo(), to: directory.appendingPathComponent("roam.gif"))
        try ImageExporter.exportSpecies(to: directory.appendingPathComponent("species.png"))
        try ImageExporter.exportPreview(to: directory.appendingPathComponent("scenes.png"))
        try ImageExporter.exportBuilder(to: directory.appendingPathComponent("builder.png"))
        try ImageExporter.writePNG(ImageExporter.renderIcon(), to: directory.appendingPathComponent("icon.png"))
    }

    private static func banner() -> CGImage {
        let ctx = ImageExporter.makeContext(width: 1280, height: 420)
        paintBackground(ctx)
        drawText("Amazing Pet", size: 16, scale: 6, color: PixelTheme.highlight, centerX: 640, top: 50, in: ctx)
        drawText("A tiny pixel pet that lives in your macOS menu bar", size: 11, scale: 2.5, color: PixelTheme.muted, centerX: 640, top: 175, in: ctx)

        let looks = [
            PetLook(species: .cat), PetLook(species: .dog, coat: .spotted), PetLook(species: .fox),
            PetLook(species: .rabbit, coat: .white), PetLook(species: .hamster), PetLook(species: .bird, coat: .yellow),
            PetLook(species: .fish), PetLook(species: .turtle),
        ]
        let scale = 6.0
        let spacing = 36.0
        let width = Double(looks.count) * 16 * scale + Double(looks.count - 1) * spacing
        let ground = 70.0
        ctx.setFillColor(PixelTheme.ground)
        ctx.fill(CGRect(x: 0, y: ground - 8, width: 1280, height: 8))
        for (index, look) in looks.enumerated() {
            let sprite = PetSprites(look: look).walk[index % 2]
            let x = (1280 - width) / 2 + Double(index) * (16 * scale + spacing)
            ctx.draw(sprite.right, in: CGRect(x: x, y: ground, width: 16 * scale, height: 12 * scale))
        }
        return ctx.makeImage()!
    }

    private static func menuBarDemo() -> [CGImage] {
        let scale = 5.0
        let size = (width: 560, height: 140)
        let bar = CGRect(x: 20, y: 54, width: 520, height: 70)
        let simulation = PetSimulation(activity: .yarn, dice: Dice(seed: 11))
        let script: [(seconds: Double, text: String, start: (PetSimulation) -> Void)] = [
            (3.5, "Plays with a yarn ball", { $0.setActivity(.yarn) }),
            (3, "Hunts a toy mouse when the CPU is busy", { $0.setActivity(.mouse) }),
            (3, "Chases a laser under heavy load", { $0.setActivity(.laser) }),
            (2.5, "Your Mac is overheating!", { $0.setActivity(.overheated) }),
            (2.5, "Memory is full", { $0.setActivity(.memoryFull) }),
            (2.5, "Purrs when you pet it", { $0.setActivity(.sleep); $0.stroke() }),
        ]
        return script.flatMap { part -> [CGImage] in
            part.start(simulation)
            return (0..<Int(part.seconds * gifFPS)).map { _ in
                simulation.step(1 / gifFPS)
                let ctx = ImageExporter.makeContext(width: size.width, height: size.height)
                paintBackground(ctx)
                ctx.setFillColor(Palette.color(0x2B2A33))
                ctx.fill(bar)
                let origin = CGPoint(x: bar.midX - Stage.menuBar.width * scale / 2, y: bar.midY - Stage.menuBar.height * scale / 2)
                ImageExporter.draw(simulation.snapshot(), in: ctx, origin: origin, scale: scale)
                drawText(part.text, size: 11, scale: 2, color: caption, centerX: Double(size.width) / 2, top: 100, in: ctx)
                return ctx.makeImage()!
            }
        }
    }

    private static func roamDemo() -> [CGImage] {
        let stage = Stage(width: 200, height: 110)
        let scale = 3.0
        let windows = [Box(x: 18, y: 52, width: 70, height: 58), Box(x: 118, y: 34, width: 62, height: 42)]
        let cursor = (x: 104.0, y: 96.0)
        let simulation = PetSimulation(stage: stage, activity: .explore, look: PetLook(species: .cat, coat: .gray), dice: Dice(seed: 4))
        simulation.world = World(occluders: windows, cursor: cursor)
        simulation.drop(atCenter: 150)
        let script: [(seconds: Double, text: String, activity: Activity)] = [
            (7, "Jumps out of the menu bar and explores your windows", .explore),
            (8, "Plays hide and seek behind them", .peekaboo),
            (6, "Hunts the cursor you left behind", .cursor),
            (3, "Zoomies!", .zoomies),
        ]
        return script.flatMap { part -> [CGImage] in
            simulation.setActivity(part.activity)
            return (0..<Int(part.seconds * gifFPS)).map { _ in
                simulation.step(1 / gifFPS)
                let ctx = ImageExporter.makeContext(width: Int(stage.width * scale), height: Int(stage.height * scale) + 40)
                ctx.setFillColor(Palette.color(0x3A6F8F))
                ctx.fill(CGRect(x: 0, y: 0, width: ctx.width, height: ctx.height))
                ImageExporter.draw(simulation.snapshot(), in: ctx, origin: .zero, scale: scale, stage: stage)
                for window in windows { drawWindow(window, stage: stage, scale: scale, in: ctx) }
                if part.activity == .cursor { drawSprite(cursorArrow, x: cursor.x, y: cursor.y, stage: stage, scale: scale, in: ctx) }
                ctx.setFillColor(PixelTheme.background)
                ctx.fill(CGRect(x: 0, y: stage.height * scale, width: Double(ctx.width), height: 40))
                drawText(part.text, size: 11, scale: 2, color: caption, centerX: stage.width * scale / 2, top: 8, in: ctx)
                return ctx.makeImage()!
            }
        }
    }

    private static let cursorArrow = Sprite([
        "K.....", "KK....", "KWK...", "KWWK..", "KWWWK.", "KWWWWK", "KWKKK.", "KK....", "K.....",
    ])

    private static func drawWindow(_ box: Box, stage: Stage, scale: Double, in ctx: CGContext) {
        let rect = CGRect(
            x: box.minX * scale, y: (stage.height - box.maxY) * scale,
            width: (box.maxX - box.minX) * scale, height: (box.maxY - box.minY) * scale
        )
        ctx.setFillColor(Palette.color(0x2A1C17))
        ctx.fill(rect)
        ctx.setFillColor(Palette.color(0xECEAF4))
        ctx.fill(rect.insetBy(dx: scale, dy: scale))
        ctx.setFillColor(Palette.color(0xC9C5DA))
        ctx.fill(CGRect(x: rect.minX + scale, y: rect.maxY - 5 * scale, width: rect.width - 2 * scale, height: 4 * scale))
    }

    private static func drawSprite(_ sprite: Sprite, x: Double, y: Double, stage: Stage, scale: Double, in ctx: CGContext) {
        let rect = CGRect(
            x: x * scale, y: (stage.height - y - Double(sprite.height)) * scale,
            width: Double(sprite.width) * scale, height: Double(sprite.height) * scale
        )
        ctx.draw(sprite.right, in: rect)
    }

    private static func paintBackground(_ ctx: CGContext) {
        ctx.setFillColor(PixelTheme.background)
        ctx.fill(CGRect(x: 0, y: 0, width: ctx.width, height: ctx.height))
        ctx.setFillColor(PixelTheme.dots)
        for x in stride(from: 9, to: ctx.width, by: 18) {
            for y in stride(from: 9, to: ctx.height, by: 18) {
                ctx.fill(CGRect(x: x, y: y, width: 3, height: 3))
            }
        }
    }

    private static let textMargin = 16.0

    private static func drawText(_ text: String, size: CGFloat, scale: Double, color: CGColor, centerX: Double, top: Double, in ctx: CGContext) {
        guard let image = PixelText.render(text, size: size, color: color) else { return }
        let scale = fittingScale(scale, imageWidth: Double(image.width), available: Double(ctx.width) - 2 * textMargin)
        let width = Double(image.width) * scale
        let height = Double(image.height) * scale
        let x = max(textMargin, min(centerX - width / 2, Double(ctx.width) - textMargin - width))
        ctx.draw(image, in: CGRect(x: x.rounded(), y: Double(ctx.height) - top - height, width: width, height: height))
    }

    private static func fittingScale(_ preferred: Double, imageWidth: Double, available: Double) -> Double {
        var scale = preferred
        while scale > 1, imageWidth * scale > available { scale -= 0.5 }
        return scale
    }

    private static func writeGIF(_ frames: [CGImage], to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames.count, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let loop = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary
        let delay = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / gifFPS]] as CFDictionary
        CGImageDestinationSetProperties(destination, loop)
        for frame in frames { CGImageDestinationAddImage(destination, frame, delay) }
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    }
}
