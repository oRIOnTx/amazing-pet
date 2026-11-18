import AppKit
import CoreText
import AmazingPetCore
import SwiftUI

enum PixelTheme {
    static let unit: CGFloat = 3
    static let fontName = "Silom"

    static let background = Palette.color(0x1E1B2E)
    static let dots = Palette.color(0x2A2640)
    static let panel = Palette.color(0x2E2A45)
    static let border = Palette.color(0x0D0B15)
    static let text = Palette.color(0xF6EEDC)
    static let muted = Palette.color(0x9C93B8)
    static let accent = Palette.color(0xF4A04A)
    static let highlight = Palette.color(0xFFE066)
    static let ground = Palette.color(0x3B3557)
}

extension Color {
    init(_ cgColor: CGColor) { self.init(cgColor: cgColor) }
}

enum PixelText {
    static func render(_ text: String, size: CGFloat, color: CGColor) -> CGImage? {
        let font = CTFontCreateWithName(PixelTheme.fontName as CFString, size, nil)
        let line = CTLineCreateWithAttributedString(attributed(text, font: font, color: color, wordGap: (size * 0.3).rounded()))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let width = Int(ceil(CTLineGetTypographicBounds(line, &ascent, &descent, nil)))
        let height = Int(ceil(ascent + descent))
        guard width > 0, height > 0, let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.setAllowsAntialiasing(false)
        ctx.setShouldAntialias(false)
        ctx.setAllowsFontSmoothing(false)
        ctx.textPosition = CGPoint(x: 0, y: ceil(descent))
        CTLineDraw(line, ctx)
        return ctx.makeImage()
    }

    private static func attributed(_ text: String, font: CTFont, color: CGColor, wordGap: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
        ])
        let kern = NSAttributedString.Key(kCTKernAttributeName as String)
        for (offset, character) in text.utf16.enumerated() where character == 0x20 {
            result.addAttribute(kern, value: wordGap, range: NSRange(location: offset, length: 1))
        }
        return result
    }
}

struct PixelImage: View {
    let image: CGImage
    var scale: CGFloat = PixelTheme.unit

    var body: some View {
        Image(decorative: image, scale: 1)
            .interpolation(.none)
            .resizable()
            .frame(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
    }
}

struct PixelLabel: View {
    let text: String
    var size: CGFloat = 12
    var color = PixelTheme.text
    var scale: CGFloat = 2

    var body: some View {
        if let image = PixelText.render(text, size: size, color: color) {
            PixelImage(image: image, scale: scale)
                .accessibilityLabel(text)
        }
    }
}

struct NotchedRectangle: Shape {
    var notch = PixelTheme.unit

    func path(in rect: CGRect) -> Path {
        let n = notch
        return Path { p in
            p.addLines([
                CGPoint(x: rect.minX + n, y: rect.minY), CGPoint(x: rect.maxX - n, y: rect.minY),
                CGPoint(x: rect.maxX - n, y: rect.minY + n), CGPoint(x: rect.maxX, y: rect.minY + n),
                CGPoint(x: rect.maxX, y: rect.maxY - n), CGPoint(x: rect.maxX - n, y: rect.maxY - n),
                CGPoint(x: rect.maxX - n, y: rect.maxY), CGPoint(x: rect.minX + n, y: rect.maxY),
                CGPoint(x: rect.minX + n, y: rect.maxY - n), CGPoint(x: rect.minX, y: rect.maxY - n),
                CGPoint(x: rect.minX, y: rect.minY + n), CGPoint(x: rect.minX + n, y: rect.minY + n),
            ])
            p.closeSubpath()
        }
    }
}

struct PixelPanel: ViewModifier {
    var fill = PixelTheme.panel
    var border = PixelTheme.border
    var shadow = true

    func body(content: Content) -> some View {
        let unit = PixelTheme.unit
        content
            .padding(unit)
            .background(
                ZStack {
                    NotchedRectangle().fill(Color(border))
                    NotchedRectangle().fill(Color(fill)).padding(unit)
                }
            )
            .background(
                NotchedRectangle().fill(Color.black.opacity(shadow ? 0.45 : 0)).offset(x: unit, y: unit)
            )
    }
}

extension View {
    func pixelPanel(fill: CGColor = PixelTheme.panel, border: CGColor = PixelTheme.border, shadow: Bool = true) -> some View {
        modifier(PixelPanel(fill: fill, border: border, shadow: shadow))
    }
}

struct PixelButtonStyle: ButtonStyle {
    var fill = PixelTheme.panel

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .pixelPanel(fill: fill, shadow: !pressed)
            .offset(x: pressed ? PixelTheme.unit : 0, y: pressed ? PixelTheme.unit : 0)
            .contentShape(Rectangle())
    }
}

struct PixelBackground: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(PixelTheme.background)))
            let step = PixelTheme.unit * 6
            var dots = Path()
            for x in stride(from: step / 2, to: size.width, by: step) {
                for y in stride(from: step / 2, to: size.height, by: step) {
                    dots.addRect(CGRect(x: x, y: y, width: PixelTheme.unit, height: PixelTheme.unit))
                }
            }
            ctx.fill(dots, with: .color(Color(PixelTheme.dots)))
        }
    }
}
