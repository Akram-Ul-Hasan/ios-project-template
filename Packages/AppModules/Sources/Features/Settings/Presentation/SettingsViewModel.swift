import Core
import DesignSystem
import Foundation
import Observation
import os

@MainActor
@Observable
public final class SettingsViewModel {
    public var logoutDialog: DialogModel?
    public private(set) var permissionStatuses: [AppPermission: PermissionStatus] = [:]
    /// The exported log file, ready to share.
    public private(set) var exportedLogs: URL?
    public private(set) var isExportingLogs = false

    @ObservationIgnored public let localization: LocalizationManager
    @ObservationIgnored public let theme: ThemeManager
    @ObservationIgnored public let version: (marketing: String, build: String)
    /// Development and staging only: production never offers log export.
    @ObservationIgnored public let isDiagnosticsEnabled: Bool
    @ObservationIgnored private let feedback: any FeedbackPresenting
    @ObservationIgnored private let logExporter: LogExporter
    @ObservationIgnored private let permissions: any PermissionManager
    @ObservationIgnored private let onLogout: @MainActor () -> Void

    public init(
        localization: LocalizationManager,
        theme: ThemeManager,
        permissions: any PermissionManager,
        version: (marketing: String, build: String),
        isDiagnosticsEnabled: Bool,
        feedback: any FeedbackPresenting,
        logExporter: LogExporter = LogExporter(),
        onLogout: @escaping @MainActor () -> Void
    ) {
        self.localization = localization
        self.theme = theme
        self.permissions = permissions
        self.version = version
        self.isDiagnosticsEnabled = isDiagnosticsEnabled
        self.feedback = feedback
        self.logExporter = logExporter
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

    /// Writes this run's logs to a file for QA to attach to a bug report.
    public func exportLogs() async {
        guard isDiagnosticsEnabled, !isExportingLogs else { return }
        isExportingLogs = true
        defer { isExportingLogs = false }
        do {
            exportedLogs = try await logExporter.export(since: .distantPast)
        } catch {
            AppLogger.lifecycle.error("log export failed: \(error.localizedDescription, privacy: .public)")
            feedback.show(error: ResponseError.from(error))
        }
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
