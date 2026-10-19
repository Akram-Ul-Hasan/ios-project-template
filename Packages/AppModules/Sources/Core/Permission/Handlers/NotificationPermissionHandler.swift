import UserNotifications

public struct NotificationPermissionHandler: PermissionHandler {
    public init() {}

    public func status() async -> PermissionStatus {
        Self.map(await UNUserNotificationCenter.current().notificationSettings().authorizationStatus)
    }

    public func request() async -> PermissionStatus {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        return await status()
    }

    static func map(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .granted
        case .provisional, .ephemeral: .limited
        case .denied: .denied
        @unknown default: .denied
        }
    }
}
