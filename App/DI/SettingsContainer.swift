import Core
import Foundation
import SettingsPresentation
import SharedDomain

extension AppContainer {
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            localization: localization, theme: theme, permissions: permissions, version: Self.appVersion,
            isDiagnosticsEnabled: env.isDiagnosticsEnabled, feedback: feedback,
            onLogout: { [weak self] in Task { await self?.logout() } })
    }

    /// Revokes the session on the backend (best effort), then wipes local data; RootView then shows login.
    func logout() async {
        try? await auth.logoutUseCase()
        await sessionManager.logout()
    }

    private static var appVersion: (marketing: String, build: String) {
        let info = Bundle.main.infoDictionary ?? [:]
        return (info["CFBundleShortVersionString"] as? String ?? "-", info["CFBundleVersion"] as? String ?? "-")
    }
}
