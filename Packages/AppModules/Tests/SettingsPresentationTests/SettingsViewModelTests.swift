import Core
import DesignSystem
import SettingsPresentation
import Testing

@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {
    private func makeViewModel(onLogout: @escaping @MainActor () -> Void = {}) -> SettingsViewModel {
        let preferences = InMemoryPreferencesStore()
        return SettingsViewModel(
            localization: LocalizationManager(preferences: preferences, preferredLanguages: ["en"]),
            theme: ThemeManager(preferences: preferences), version: ("1.0", "7"), onLogout: onLogout)
    }

    @Test("Logout asks for confirmation first, then logs out on confirm")
    func logout() {
        var loggedOut = false
        let model = makeViewModel { loggedOut = true }
        model.confirmLogout(title: "Log out?", message: "m", confirm: "Log out", cancel: "Cancel")
        #expect(model.logoutDialog?.primary.role == .destructive)
        #expect(!loggedOut)
        model.logoutDialog?.primary.action()
        #expect(loggedOut)
    }
}
