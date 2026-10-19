import Foundation
import Testing

@testable import Localization

// Serialized: every test switches the process-wide active language.
@Suite("Localization", .serialized)
struct LocalizationTests {
    @Test("Every language has exactly the same keys as English")
    func catalogIsComplete() throws {
        let english = try keys(for: .en)
        #expect(!english.isEmpty)
        for language in AppLanguage.allCases where language != .en {
            let other = try keys(for: language)
            #expect(english.subtracting(other).isEmpty, "\(language) is missing \(english.subtracting(other).sorted())")
            #expect(other.subtracting(english).isEmpty, "\(language) has extra \(other.subtracting(english).sorted())")
        }
    }

    @Test("Applying a language switches the strings")
    func applySwitchesLanguage() {
        defer { LocalizationBundle.apply(.en) }
        LocalizationBundle.apply(.en)
        #expect(L10n.Common.retry == "Retry")
        LocalizationBundle.apply(.bn)
        #expect(LocalizationBundle.language == .bn)
        #expect(L10n.Common.retry == "আবার চেষ্টা করুন")
    }

    @Test("Plural variations follow the count", arguments: [(1, "1 item"), (3, "3 items")])
    func plurals(count: Int, expected: String) {
        LocalizationBundle.apply(.en)
        #expect(L10n.Common.itemsCount(count) == expected)
    }

    @Test("Unknown key falls back to the key itself")
    func missingKey() {
        #expect(L10n.tr("does.not.exist") == "does.not.exist")
    }

    @Test(
        "Preferred language picks the first supported one",
        arguments: [
            (["bn-BD", "en-US"], AppLanguage.bn),
            (["fr-FR", "en-GB"], .en),
            (["fr-FR"], .en),
            ([], .en),
        ])
    func preferred(identifiers: [String], expected: AppLanguage) {
        #expect(AppLanguage.preferred(from: identifiers) == expected)
    }

    private func keys(for language: AppLanguage) throws -> Set<String> {
        let path = try #require(Bundle.module.path(forResource: language.rawValue, ofType: "lproj"))
        var keys = Set<String>()
        for table in ["Localizable.strings", "Localizable.stringsdict"] {
            if let dictionary = NSDictionary(contentsOfFile: "\(path)/\(table)") as? [String: Any] {
                keys.formUnion(dictionary.keys)
            }
        }
        return keys
    }
}
