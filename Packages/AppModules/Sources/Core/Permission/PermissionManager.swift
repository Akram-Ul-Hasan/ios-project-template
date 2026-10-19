import Foundation

#if canImport(UIKit)
    import UIKit
#endif

/// Permissions only go through here (rule 21); `PermissionGate` in DesignSystem builds the UX on top.
public protocol PermissionManager: Sendable {
    func status(of permission: AppPermission) async -> PermissionStatus
    /// Shows the system prompt if the status is `.notDetermined`, otherwise just returns the status.
    func request(_ permission: AppPermission) async -> PermissionStatus
    @MainActor func openAppSettings()
}

/// Wraps one Apple API and normalizes it to `PermissionStatus`.
public protocol PermissionHandler: Sendable {
    func status() async -> PermissionStatus
    func request() async -> PermissionStatus
}

public struct SystemPermissionManager: PermissionManager {
    private let handlers: [AppPermission: any PermissionHandler]

    public init(handlers: [AppPermission: any PermissionHandler]) {
        self.handlers = handlers
    }

    /// Every permission, backed by the real system APIs.
    public init() {
        self.init(handlers: [
            .notifications: NotificationPermissionHandler(),
            .locationWhenInUse: LocationPermissionHandler(),
            .camera: CapturePermissionHandler(media: .video),
            .microphone: CapturePermissionHandler(media: .audio),
            .photos: PhotosPermissionHandler(),
            .contacts: ContactsPermissionHandler(),
            .tracking: TrackingPermissionHandler(),
        ])
    }

    public func status(of permission: AppPermission) async -> PermissionStatus {
        await handlers[permission]?.status() ?? .restricted
    }

    public func request(_ permission: AppPermission) async -> PermissionStatus {
        guard let handler = handlers[permission] else { return .restricted }
        let status = await handler.request()
        AppLogger.security.info(
            "permission \(permission.rawValue, privacy: .public) → \(String(describing: status), privacy: .public)")
        return status
    }

    @MainActor
    public func openAppSettings() {
        #if canImport(UIKit)
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        #endif
    }
}

/// Returns fixed statuses, for SwiftUI previews and tests.
public final class FixedPermissionManager: PermissionManager {
    private let statuses: [AppPermission: PermissionStatus]
    private let afterRequest: PermissionStatus

    public init(statuses: [AppPermission: PermissionStatus], afterRequest: PermissionStatus) {
        self.statuses = statuses
        self.afterRequest = afterRequest
    }

    public func status(of permission: AppPermission) async -> PermissionStatus {
        statuses[permission] ?? .notDetermined
    }
    public func request(_ permission: AppPermission) async -> PermissionStatus { afterRequest }
    @MainActor public func openAppSettings() {}
}
