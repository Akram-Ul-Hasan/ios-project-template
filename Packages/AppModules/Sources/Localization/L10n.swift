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

    public enum Error {
        public static var title: String { tr("error.title") }
        public static var generic: String { tr("error.generic") }
        public static var network: String { tr("error.network") }
        public static var timeout: String { tr("error.timeout") }
        public static var unauthorized: String { tr("error.unauthorized") }
        public static var forbidden: String { tr("error.forbidden") }
        public static var notFound: String { tr("error.not_found") }
        public static var validation: String { tr("error.validation") }
        public static var server: String { tr("error.server") }
        public static var maintenance: String { tr("error.maintenance") }
        public static var updateRequired: String { tr("error.update_required") }
        public static var outOfStock: String { tr("error.out_of_stock") }
        public static var couponExpired: String { tr("error.coupon_expired") }
        public static var subscriptionRequired: String { tr("error.subscription_required") }
    }

    public enum Validation {
        public static var required: String { tr("validation.required") }
        public static func tooShort(_ min: Int) -> String { tr("validation.too_short", min) }
        public static func tooLong(_ max: Int) -> String { tr("validation.too_long", max) }
        public static var phone: String { tr("validation.phone") }
        public static var email: String { tr("validation.email") }
        public static func otp(_ length: Int) -> String { tr("validation.otp", length) }
        public static var password: String { tr("validation.password") }
        public static var mismatch: String { tr("validation.mismatch") }
        public static var outOfRange: String { tr("validation.out_of_range") }
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
