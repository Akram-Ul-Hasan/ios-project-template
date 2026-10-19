import Core
import UserNotifications

/// Push taps open the exact screen (§6c): payload `deeplink` → `DeepLinkParser` → `DeepLinkHandler` → router.
extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Also show pushes while the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// At cold start this arrives before the UI exists; `DeepLinkHandler` keeps the link until it can be shown.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let link = response.notification.request.content.userInfo[DeepLinkConstants.pushPayloadKey] as? String
        await MainActor.run {
            container?.deepLinks.receive(DeepLinkParser.parse(pushLink: link))
        }
    }
}
