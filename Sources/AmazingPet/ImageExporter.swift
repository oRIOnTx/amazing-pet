import CoreGraphics
import Foundation
import ImageIO
import AmazingPetCore
import SwiftUI
import UniformTypeIdentifiers

enum ImageExporter {
    private static let iconSizes = [16, 32, 128, 256, 512]
    private static let previewScale = 8.0
    private static let previewMoments = [1.0, 2.3, 3.7]

    static func exportIconset(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let master = renderIcon()
        for size in iconSizes {
            for scale in [1, 2] {
                let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
                try writePNG(resize(master, to: size * scale), to: directory.appendingPathComponent(name))
            }
        }
    }

    static func exportPreview(to file: URL) throws {
        let cellWidth = Int(Stage.menuBar.width * previewScale)
        let cellHeight = Int((Stage.menuBar.height + 4) * previewScale)
        let backgrounds = [CGColor(gray: 0.93, alpha: 1), CGColor(gray: 0.16, alpha: 1)]
        let columns = previewMoments.count * backgrounds.count
        let rows = Activity.allCases.count + 1
        let ctx = makeContext(width: cellWidth * columns, height: cellHeight * rows)

        for (row, activity) in (Activity.allCases.map(Optional.some) + [nil]).enumerated() {
            for (momentIndex, moment) in previewMoments.enumerated() {
                let scene = previewScene(activity, at: moment)
                for (bgIndex, background) in backgrounds.enumerated() {
                    let column = bgIndex * previewMoments.count + momentIndex
                    let origin = CGPoint(x: column * cellWidth, y: (rows - 1 - row) * cellHeight)
                    ctx.setFillColor(background)
                    ctx.fill(CGRect(origin: origin, size: CGSize(width: cellWidth, height: cellHeight)))
                    draw(scene, in: ctx, origin: CGPoint(x: origin.x, y: origin.y + previewScale * 2), scale: previewScale)
                }
            }
        }
        try writePNG(ctx.makeImage()!, to: file)
    }

    static func exportSpecies(to file: URL) throws {
        let scale = 6.0
        let cell = 18.0 * scale
        let columns = 5 + Coat.allCases.count
        let ctx = makeContext(width: Int(cell) * columns, height: Int(cell) * Species.allCases.count)
        ctx.setFillColor(CGColor(gray: 0.93, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: ctx.width, height: ctx.height))
        for (row, species) in Species.allCases.enumerated() {
            let frames = PetSprites(look: PetLook(species: species)).all
            let coats = species.coats.map { PetSprites(look: PetLook(species: species, coat: $0)).walk[0] }
            for (column, sprite) in (frames + coats).enumerated() {
                let origin = CGPoint(x: Double(column) * cell + scale, y: Double(Species.allCases.count - 1 - row) * cell + scale)
                ctx.draw(sprite.right, in: CGRect(origin: origin, size: CGSize(width: Double(sprite.width) * scale, height: Double(sprite.height) * scale)))
            }
        }
        try writePNG(ctx.makeImage()!, to: file)
    }

    @MainActor
    static func exportBuilder(to file: URL) throws {
        let model = PetBuilderModel(profile: PetProfile(name: "Biscuit", look: PetLook(species: .rabbit, coat: .brown, eyes: .green)))
        let renderer = ImageRenderer(content: PetBuilderView(model: model, isSnapshot: true))
        renderer.scale = 2
        guard let image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
        try writePNG(image, to: file)
    }

    private static func previewScene(_ activity: Activity?, at time: Double) -> SceneSnapshot {
        let simulation = PetSimulation(activity: activity ?? .yarn, dice: Dice(seed: 7))
        if activity == nil { simulation.stroke() }
        for _ in 0..<Int(time * 20) { simulation.step(0.05) }
        return simulation.snapshot()
    }

    static func renderIcon() -> CGImage {
        let size = 1024.0
        let ctx = makeContext(width: Int(size), height: Int(size))
        let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
        ctx.addPath(CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil))
        ctx.clip()
        let gradient = CGGradient(
            colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
            colors: [CGColor(srgbRed: 1, green: 0.93, blue: 0.80, alpha: 1), CGColor(srgbRed: 1, green: 0.74, blue: 0.47, alpha: 1)] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: tile.maxY), end: CGPoint(x: 0, y: tile.minY), options: [])

        let pixel = 34.0
        let ground = tile.minY + pixel * 4
        let pet = Sprites.defaultPet.run[0]
        let catRect = CGRect(x: tile.minX + pixel * 1, y: ground, width: Double(pet.width) * pixel, height: Double(pet.height) * pixel)
        ctx.draw(pet.right, in: catRect)
        let yarn = Sprites.yarn[0]
        ctx.draw(yarn.right, in: CGRect(x: catRect.maxX, y: ground, width: Double(yarn.width) * pixel, height: Double(yarn.height) * pixel))
        return ctx.makeImage()!
    }

    static func exportRoam(to file: URL) throws {
        let stage = Stage(width: 110, height: 40)
        let scale = 4.0
        let games = Activity.roamGames + [.sleep]
        let rowHeight = Int(stage.height * scale)
        let ctx = makeContext(width: Int(stage.width * scale), height: rowHeight * games.count)
        for (row, game) in games.enumerated() {
            let origin = CGPoint(x: 0, y: (games.count - 1 - row) * rowHeight)
            ctx.setFillColor(row.isMultiple(of: 2) ? CGColor(gray: 0.93, alpha: 1) : CGColor(gray: 0.85, alpha: 1))
            ctx.fill(CGRect(origin: origin, size: CGSize(width: ctx.width, height: rowHeight)))
            let simulation = PetSimulation(stage: stage, activity: game, look: PetLook(species: .dog), dice: Dice(seed: 3))
            for _ in 0..<45 { simulation.step(0.05) }
            draw(simulation.snapshot(), in: ctx, origin: origin, scale: scale, stage: stage)
        }
        try writePNG(ctx.makeImage()!, to: file)
    }

    static func draw(_ scene: SceneSnapshot, in ctx: CGContext, origin: CGPoint, scale: Double, stage: Stage = .menuBar) {
        for item in [scene.pet] + [scene.prop].compactMap(\.self) + scene.effects {
            let height = Double(item.sprite.height)
            let rect = CGRect(
                x: origin.x + item.x * scale,
                y: origin.y + (stage.height - item.y - height) * scale,
                width: Double(item.sprite.width) * scale,
                height: height * scale
            )
            ctx.setAlpha(CGFloat(item.opacity))
            ctx.draw(item.sprite.image(facingRight: item.facingRight), in: rect)
        }
        ctx.setAlpha(1)
    }

    private static func resize(_ image: CGImage, to size: Int) -> CGImage {
        let ctx = makeContext(width: size, height: size)
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
        return ctx.makeImage()!
    }

    static func makeContext(width: Int, height: Int) -> CGContext {
        let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.interpolationQuality = .none
        return ctx
    }

    static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    }
}
