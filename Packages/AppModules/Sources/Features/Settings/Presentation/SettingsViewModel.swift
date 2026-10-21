import Core
import DesignSystem
import Observation
import os

@MainActor
@Observable
public final class SettingsViewModel {
    public var logoutDialog: DialogModel?
    public private(set) var permissionStatuses: [AppPermission: PermissionStatus] = [:]

    @ObservationIgnored public let localization: LocalizationManager
    @ObservationIgnored public let theme: ThemeManager
    @ObservationIgnored public let version: (marketing: String, build: String)
    @ObservationIgnored private let permissions: any PermissionManager
    @ObservationIgnored private let onLogout: @MainActor () -> Void

    public init(
        localization: LocalizationManager,
        theme: ThemeManager,
        permissions: any PermissionManager,
        version: (marketing: String, build: String),
        onLogout: @escaping @MainActor () -> Void
    ) {
        self.localization = localization
        self.theme = theme
        self.permissions = permissions
        self.version = version
        self.onLogout = onLogout
    }

    /// Re-read on appear and whenever the app returns from the Settings app.
    public func loadPermissions() async {
        var statuses: [AppPermission: PermissionStatus] = [:]
        for permission in AppPermission.allCases {
            statuses[permission] = await permissions.status(of: permission)
        }
        permissionStatuses = statuses
    }

    public func openAppSettings() {
        permissions.openAppSettings()
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
