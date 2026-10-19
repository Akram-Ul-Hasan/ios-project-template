import Foundation
import Localization
import Testing

@testable import Core

extension LanguageSensitive {
    @Suite("LocalizationManager")
    @MainActor
    struct LocalizationManagerTests {
        init() { LocalizationBundle.apply(.en) }

        @Test("First launch follows the device language, falling back to English")
        func firstLaunch() {
            #expect(
                LocalizationManager(preferences: InMemoryPreferencesStore(), preferredLanguages: ["bn-BD"]).language
                    == .bn)
            #expect(
                LocalizationManager(preferences: InMemoryPreferencesStore(), preferredLanguages: ["fr"]).language == .en
            )
            LocalizationBundle.apply(.en)
        }

        @Test("A saved choice wins over the device language")
        func savedChoice() {
            let preferences = InMemoryPreferencesStore()
            preferences.set(.bn, for: .language)
            let manager = LocalizationManager(preferences: preferences, preferredLanguages: ["en-US"])
            #expect(manager.language == .bn)
            #expect(LocalizationBundle.language == .bn)
            LocalizationBundle.apply(.en)
        }

        @Test("Switching saves, activates the strings and updates the locale")
        func switching() {
            defer { LocalizationBundle.apply(.en) }
            let preferences = InMemoryPreferencesStore()
            let manager = LocalizationManager(preferences: preferences, preferredLanguages: ["en"])
            manager.set(.bn)
            #expect(preferences.value(.language) == .bn)
            #expect(L10n.Common.retry == "আবার চেষ্টা করুন")
            #expect(manager.locale.identifier == "bn_BD@numbers=beng")
        }

        @Test("LanguageInterceptor sends the active language")
        func acceptLanguage() async throws {
            defer { LocalizationBundle.apply(.en) }
            struct Ping: Endpoint {
                var path: String { "/ping" }
                var method: HTTPMethod { .get }
            }
            let request = URLRequest(url: URL(string: "https://x.test")!)
            LocalizationBundle.apply(.bn)
            let adapted = try await LanguageInterceptor().adapt(request, for: Ping())
            #expect(adapted.value(forHTTPHeaderField: "Accept-Language") == "bn")
        }
    }
}
