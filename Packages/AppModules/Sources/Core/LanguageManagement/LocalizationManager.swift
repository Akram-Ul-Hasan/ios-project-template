import Foundation
import Localization
import Observation

/// The in-app language switch (§6k). Persists the choice and activates it in `LocalizationBundle`;
/// the root view re-renders through `.id(manager.language)`, so no restart is needed.
@MainActor
@Observable
public final class LocalizationManager {
    public private(set) var language: AppLanguage

    @ObservationIgnored private let preferences: any PreferencesStore

    /// First launch: the device language if supported, else English.
    public init(preferences: any PreferencesStore, preferredLanguages: [String] = Locale.preferredLanguages) {
        self.preferences = preferences
        language = preferences.value(.language) ?? AppLanguage.preferred(from: preferredLanguages)
        LocalizationBundle.apply(language)
    }

    /// For `.environment(\.locale, …)` and every formatter.
    public var locale: Locale { Self.locale(for: language) }

    public var formatters: AppFormatters { AppFormatters(locale: locale) }

    public func set(_ language: AppLanguage) {
        guard language != self.language else { return }
        preferences.set(language, for: .language)
        LocalizationBundle.apply(language)
        self.language = language
    }

    static func locale(for language: AppLanguage) -> Locale {
        switch language {
        case .en: Locale(identifier: "en_\(LocaleConstants.regionCode)")
        // Bangla digits (১২৩) in numbers, prices and dates.
        case .bn: Locale(identifier: "bn_\(LocaleConstants.regionCode)@numbers=beng")
        }
    }
}
