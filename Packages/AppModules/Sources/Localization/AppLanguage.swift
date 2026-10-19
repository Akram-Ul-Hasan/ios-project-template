/// Languages the app ships. Raw values are the `.lproj` names in the string catalog.
public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case en
    case bn

    /// Shown in the language picker in the language itself, so it never needs translating.
    public var nativeName: String {
        switch self {
        case .en: "English"
        case .bn: "বাংলা"
        }
    }

    public var isRTL: Bool {
        switch self {
        case .en, .bn: false
        }
    }

    /// First supported language in the user's preference order (e.g. `Locale.preferredLanguages`), else English.
    public static func preferred(from identifiers: [String]) -> AppLanguage {
        for identifier in identifiers {
            let code = identifier.split(separator: "-").first.map(String.init) ?? identifier
            if let language = AppLanguage(rawValue: code) { return language }
        }
        return .en
    }
}
