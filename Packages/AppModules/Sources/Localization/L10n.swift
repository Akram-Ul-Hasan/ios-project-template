import Foundation

/// Type-safe access to `Localizable.xcstrings`. Every user-facing string goes through here (rule 18).
/// Add a key to the catalog in every language first, then its accessor below.
public enum L10n {
    public enum Common {
        public static var ok: String { tr("common.ok") }
        public static var cancel: String { tr("common.cancel") }
        public static var close: String { tr("common.close") }
        public static var `continue`: String { tr("common.continue") }
        public static var done: String { tr("common.done") }
        public static var openSettings: String { tr("common.open_settings") }
        public static var retry: String { tr("common.retry") }
        public static func itemsCount(_ count: Int) -> String { tr("common.items_count", count) }
    }
}

extension L10n {
    /// Looks the key up in the active language, falling back to English when it's missing there.
    static func tr(_ key: String, _ arguments: any CVarArg...) -> String {
        var format = LocalizationBundle.current.localizedString(forKey: key, value: missing, table: nil)
        if format == missing {
            format = LocalizationBundle.fallback.localizedString(forKey: key, value: key, table: nil)
        }
        // The format carries the catalog's plural rules; the locale picks the right variation.
        return String(format: format, locale: LocalizationBundle.locale, arguments: arguments)
    }

    private static let missing = "\u{0}missing"
}
