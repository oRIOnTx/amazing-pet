import Foundation
import Testing

struct LocalizationTests {
    private static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    private static func englishStrings() throws -> [String: String] {
        let source = try String(contentsOf: root.appendingPathComponent("Sources/AmazingPet/L10n.swift"), encoding: .utf8)
        let pattern = try NSRegularExpression(pattern: #"tr\("([^"]+)", "((?:[^"\\]|\\.)*)"\)"#)
        let matches = pattern.matches(in: source, range: NSRange(source.startIndex..., in: source))
        return Dictionary(matches.map { match in
            (String(source[Range(match.range(at: 1), in: source)!]), String(source[Range(match.range(at: 2), in: source)!]))
        }) { first, _ in first }
    }

    private static func translations(_ language: String) throws -> [String: String] {
        let url = root.appendingPathComponent("Resources/\(language).lproj/Localizable.strings")
        return try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as! [String: String]
    }

    private static func placeholders(_ text: String) -> [String] {
        let pattern = try! NSRegularExpression(pattern: "%(@|d)")
        return pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { (text as NSString).substring(with: $0.range) }
    }

    @Test func englishDefaultsAreFound() throws {
        #expect(try Self.englishStrings().count > 40)
    }

    @Test(arguments: ["uk"])
    func everyKeyIsTranslated(language: String) throws {
        let english = try Self.englishStrings()
        let translated = try Self.translations(language)
        #expect(Set(english.keys).subtracting(translated.keys).isEmpty)
        #expect(Set(translated.keys).subtracting(english.keys).isEmpty)
    }

    @Test(arguments: ["uk"])
    func placeholdersMatchEnglish(language: String) throws {
        let english = try Self.englishStrings()
        for (key, value) in try Self.translations(language) {
            guard let source = english[key] else { continue }
            #expect(Self.placeholders(value) == Self.placeholders(source), "\(key)")
        }
    }
}
