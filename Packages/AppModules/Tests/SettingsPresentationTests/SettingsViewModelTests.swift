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
            theme: ThemeManager(preferences: preferences),
            permissions: FixedPermissionManager(
                statuses: [.camera: .denied, .photos: .limited], afterRequest: .granted),
            version: ("1.0", "7"), onLogout: onLogout)
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

    @Test("Loads every permission's status")
    func permissions() async {
        let model = makeViewModel()
        await model.loadPermissions()
        #expect(model.permissionStatuses.count == AppPermission.allCases.count)
        #expect(model.permissionStatuses[.camera] == .denied)
        #expect(model.permissionStatuses[.photos] == .limited)
        #expect(model.permissionStatuses[.contacts] == .notDetermined)
    }
}
