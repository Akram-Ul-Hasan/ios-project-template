import Core
import DesignSystem
import UIKit
import os

/// Owns the `AppContainer` for the app's lifetime and handles UIKit-only callbacks (push, background tasks).
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// `nil` only when the build configuration is broken (missing APP_ENV / BASE_URL): the app shows
    /// `ConfigurationErrorView` instead of crashing. CI builds every flavor, so this never ships.
    let container: AppContainer?

    override init() {
        do {
            container = AppContainer(env: try Env.fromMainBundle())
        } catch {
            AppLogger.lifecycle.fault("invalid build configuration: \(String(describing: error), privacy: .public)")
            container = nil
        }
        super.init()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppTypography.registerFonts()
        // Background task handlers must be registered before launch finishes.
        let pipeline = container?.imagePipeline
        container?.refreshScheduler.registerCacheCleanup { await pipeline?.trimDiskCache() }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { ($0 < 16 ? "0" : "") + String($0, radix: 16) }.joined()
        container?.apnsToken = token
        AppLogger.lifecycle.info("registered for push: \(token, privacy: .private)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        AppLogger.lifecycle.error("push registration failed: \(error.localizedDescription, privacy: .public)")
    }
}
