import Core
import Testing

@testable import DesignSystem

@Suite("ThemeManager")
@MainActor
struct ThemeManagerTests {
    @Test("Defaults to system and persists the choice")
    func persists() {
        let preferences = InMemoryPreferencesStore()
        let manager = ThemeManager(preferences: preferences)
        #expect(manager.mode == .system && manager.colorScheme == nil)
        manager.set(.dark)
        #expect(manager.colorScheme == .dark)
        #expect(ThemeManager(preferences: preferences).mode == .dark)
    }

    @Test("An unknown saved value falls back to system")
    func unknownValue() {
        let preferences = InMemoryPreferencesStore()
        preferences.set("sepia", for: .themeMode)
        #expect(ThemeManager(preferences: preferences).mode == .system)
    }
}
