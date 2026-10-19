import Foundation
import os

/// Holds which language's strings are active. It knows *which* bundle is active, not *why*:
/// persisting the user's choice is `LocalizationManager`'s job (Core).
public enum LocalizationBundle {
    private struct State: Sendable {
        var language: AppLanguage
        var bundle: Bundle
    }

    private static let state = OSAllocatedUnfairLock(
        initialState: State(language: .en, bundle: lprojBundle(for: .en))
    )

    public static var language: AppLanguage { state.withLock { $0.language } }

    /// Bundle that `L10n` reads strings from.
    public static var current: Bundle { state.withLock { $0.bundle } }

    /// Locale for formatting placeholders in the active language (plural rules, digits).
    public static var locale: Locale { Locale(identifier: language.rawValue) }

    /// English strings, the fallback when a key is missing in the active language.
    static let fallback = lprojBundle(for: .en)

    public static func apply(_ language: AppLanguage) {
        let bundle = lprojBundle(for: language)
        state.withLock { $0 = State(language: language, bundle: bundle) }
    }

    private static func lprojBundle(for language: AppLanguage) -> Bundle {
        guard let path = Bundle.module.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return .module }
        return bundle
    }
}
