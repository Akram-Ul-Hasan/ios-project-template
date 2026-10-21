import Core
import DesignSystem
import Observation
import os

@MainActor
@Observable
public final class SettingsViewModel {
    public var logoutDialog: DialogModel?

    @ObservationIgnored public let localization: LocalizationManager
    @ObservationIgnored public let theme: ThemeManager
    @ObservationIgnored public let version: (marketing: String, build: String)
    @ObservationIgnored private let onLogout: @MainActor () -> Void

    public init(
        localization: LocalizationManager,
        theme: ThemeManager,
        version: (marketing: String, build: String),
        onLogout: @escaping @MainActor () -> Void
    ) {
        self.localization = localization
        self.theme = theme
        self.version = version
        self.onLogout = onLogout
    }

    /// Asks first: logging out wipes the session and local data.
    public func confirmLogout(title: String, message: String, confirm: String, cancel: String) {
        logoutDialog = DialogModel(
            title: title, message: message,
            primary: DialogButton(confirm, role: .destructive) { [weak self] in self?.onLogout() },
            secondary: DialogButton(cancel, role: .cancel))
    }

    #if DEBUG
        deinit { AppLogger.lifecycle.debug("deinit SettingsViewModel") }
    #endif
}
