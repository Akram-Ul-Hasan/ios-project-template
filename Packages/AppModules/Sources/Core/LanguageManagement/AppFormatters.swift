import Foundation

/// Every price, number and date shown to the user goes through here (rule 18). Never `String(format:)`
/// or a hand-built date string. Get one from `LocalizationManager.formatters` so it follows the app language.
public struct AppFormatters: Sendable {
    public let locale: Locale
    private let timeZone: TimeZone

    public init(locale: Locale, timeZone: TimeZone = .current) {
        self.locale = locale
        self.timeZone = timeZone
    }

    /// `৳1,250` / `৳১,২৫০.৫`. Up to two decimals, none when the amount is whole.
    public func price(_ amount: Decimal) -> String {
        LocaleConstants.currencySymbol + amount.formatted(.number.locale(locale).precision(.fractionLength(0...2)))
    }

    public func number(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    public func date(
        _ date: Date, date dateStyle: Date.FormatStyle.DateStyle = .abbreviated,
        time timeStyle: Date.FormatStyle.TimeStyle = .omitted
    ) -> String {
        date.formatted(Date.FormatStyle(date: dateStyle, time: timeStyle, locale: locale, timeZone: timeZone))
    }

    /// "2 hours ago" / "২ ঘণ্টা আগে".
    public func relative(_ date: Date, to now: Date = .now) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
