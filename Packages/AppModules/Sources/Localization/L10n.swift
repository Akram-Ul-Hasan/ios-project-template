import Foundation

/// Type-safe access to `Localizable.xcstrings`. Every user-facing string goes through here (rule 18).
/// Add a key to the catalog in every language first, then its accessor below.
public enum L10n {
    public enum Account {
        public static var logout: String { tr("account.logout") }
    }

    public enum Blocking {
        public static var maintenanceTitle: String { tr("blocking.maintenance_title") }
        public static var updateTitle: String { tr("blocking.update_title") }
        public static var updateAction: String { tr("blocking.update_action") }
    }

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

    public enum Input {
        public static var showPassword: String { tr("input.show_password") }
        public static var hidePassword: String { tr("input.hide_password") }
        public static var search: String { tr("input.search") }
        public static var clear: String { tr("input.clear") }
        public static var select: String { tr("input.select") }
        public static var verificationCode: String { tr("input.verification_code") }
    }

    public enum Lock {
        public static var title: String { tr("lock.title") }
        public static var unlock: String { tr("lock.unlock") }
    }

    public enum Login {
        public static var title: String { tr("login.title") }
        public static var subtitle: String { tr("login.subtitle") }
        public static var phone: String { tr("login.phone") }
        public static var phonePlaceholder: String { tr("login.phone_placeholder") }
        public static var password: String { tr("login.password") }
        public static var submit: String { tr("login.submit") }
    }

    public enum Offline {
        public static var banner: String { tr("offline.banner") }
        public static var backOnline: String { tr("offline.back_online") }
    }

    public enum Onboarding {
        public static var title: String { tr("onboarding.title") }
        public static var message: String { tr("onboarding.message") }
        public static var getStarted: String { tr("onboarding.get_started") }
    }

    public enum Pagination {
        public static var loadMoreFailed: String { tr("pagination.load_more_failed") }
    }

    public enum Permission {
        public static var notNow: String { tr("permission.not_now") }
        public static var deniedTitle: String { tr("permission.denied_title") }
        public static var deniedMessage: String { tr("permission.denied_message") }
        public static var restrictedMessage: String { tr("permission.restricted_message") }
        public static var camera: String { tr("permission.camera") }
        public static var microphone: String { tr("permission.microphone") }
        public static var photos: String { tr("permission.photos") }
        public static var location: String { tr("permission.location") }
        public static var notifications: String { tr("permission.notifications") }
        public static var contacts: String { tr("permission.contacts") }
        public static var tracking: String { tr("permission.tracking") }
    }

    public enum Placeholder {
        public static var message: String { tr("placeholder.message") }
    }

    public enum Product {
        public static var outOfStock: String { tr("product.out_of_stock") }
        public static var addToCart: String { tr("product.add_to_cart") }
    }

    public enum Route {
        public static var productDetails: String { tr("route.product_details") }
        public static var orders: String { tr("route.orders") }
        public static var orderDetails: String { tr("route.order_details") }
        public static var settings: String { tr("route.settings") }
    }

    public enum Section {
        public static var seeAll: String { tr("section.see_all") }
    }

    public enum Session {
        public static var unlockReason: String { tr("session.unlock_reason") }
    }

    public enum Sheet {
        public static var filter: String { tr("sheet.filter") }
        public static var deliveryArea: String { tr("sheet.delivery_area") }
    }

    public enum State {
        public static var emptyTitle: String { tr("state.empty_title") }
        public static var loading: String { tr("state.loading") }
        public static var offlineTitle: String { tr("state.offline_title") }
    }

    public enum Tab {
        public static var home: String { tr("tab.home") }
        public static var categories: String { tr("tab.categories") }
        public static var cart: String { tr("tab.cart") }
        public static var account: String { tr("tab.account") }
    }

    public enum Theme {
        public static var system: String { tr("theme.system") }
        public static var light: String { tr("theme.light") }
        public static var dark: String { tr("theme.dark") }
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
