import AppKit
import AmazingPetCore
import QuartzCore

final class PetView: NSView {
    static let menuBarPixel: CGFloat = 1.5
    static let menuBarSize = NSSize(width: Stage.menuBar.width * menuBarPixel, height: Stage.menuBar.height * menuBarPixel)

    private let stage: Stage
    private let pixel: CGFloat
    private var canvasSize: NSSize { NSSize(width: stage.width * pixel, height: stage.height * pixel) }

    private let petLayer = PetView.makeLayer(z: 0)
    private let propLayer = PetView.makeLayer(z: 1)
    private let effectLayers = [PetView.makeLayer(z: 2), PetView.makeLayer(z: 2)]
    private var occlusion: [CGRect] = []

    init(frame: NSRect, stage: Stage = .menuBar, pixel: CGFloat = PetView.menuBarPixel) {
        self.stage = stage
        self.pixel = pixel
        super.init(frame: frame)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
        for sublayer in [petLayer, propLayer] + effectLayers { layer?.addSublayer(sublayer) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func setOcclusion(_ rects: [CGRect]) {
        guard rects != occlusion else { return }
        occlusion = rects
        layer?.mask = rects.isEmpty ? nil : makeMask(cutting: rects)
    }

    private func makeMask(cutting rects: [CGRect]) -> CALayer? {
        guard let ctx = CGContext(
            data: nil, width: Int(bounds.width), height: Int(bounds.height), bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
        ) else { return nil }
        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.fill(bounds)
        for rect in rects { ctx.clear(rect) }
        let mask = CALayer()
        mask.frame = bounds
        mask.contents = ctx.makeImage()
        return mask
    }

    func render(_ scene: SceneSnapshot) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        apply(scene.pet, to: petLayer)
        apply(scene.prop, to: propLayer)
        for (index, layer) in effectLayers.enumerated() {
            apply(scene.effects.indices.contains(index) ? scene.effects[index] : nil, to: layer)
        }
        CATransaction.commit()
    }

    private static func makeLayer(z: CGFloat) -> CALayer {
        let layer = CALayer()
        layer.magnificationFilter = .nearest
        layer.anchorPoint = .zero
        layer.zPosition = z
        layer.isHidden = true
        return layer
    }

    private func apply(_ item: SceneSnapshot.Item?, to layer: CALayer) {
        guard let item else {
            if !layer.isHidden { layer.isHidden = true }
            return
        }
        let image = item.sprite.image(facingRight: item.facingRight)
        if layer.contents as! CGImage? !== image { layer.contents = image }
        let frame = frame(for: item)
        if layer.frame != frame { layer.frame = frame }
        if layer.opacity != item.opacity { layer.opacity = item.opacity }
        if layer.isHidden { layer.isHidden = false }
    }

    private func frame(for item: SceneSnapshot.Item) -> NSRect {
        let height = Double(item.sprite.height)
        let rect = NSRect(
            x: (bounds.width - canvasSize.width) / 2 + item.x * pixel,
            y: (bounds.height - canvasSize.height) / 2 + (stage.height - item.y - height) * pixel,
            width: Double(item.sprite.width) * pixel,
            height: height * pixel
        )
        return backingAlignedRect(rect, options: .alignAllEdgesNearest)
    }
}
