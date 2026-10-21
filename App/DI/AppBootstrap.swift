import Core
import Foundation
import os

extension AppContainer {
    /// Launch work that must not block the first frame (§6n): runs from `RootView`'s splash.
    func bootstrap() async {
        evaluateDeviceIntegrity()
        networkMonitor.start()
        metrics.start()
        do {
            try await persistence.load()
        } catch {
            AppLogger.persistence.fault("store unavailable: \(error.localizedDescription, privacy: .public)")
        }
        await imagePipeline?.trimDiskCache()
        await pushPermission.registerIfAuthorized()
        refreshScheduler.scheduleAppRefresh()
        refreshScheduler.scheduleCacheCleanup()
    }

    /// Sensitive flows (checkout, payment) check `securityPolicy.allowsSensitiveActions(securityReport)`.
    private func evaluateDeviceIntegrity() {
        let base = Bundle.main.object(forInfoDictionaryKey: "BASE_BUNDLE_IDENTIFIER") as? String ?? ""
        let report = SecurityGuard(expectedBundlePrefix: base).evaluate()
        securityPolicy.record(report)
        securityReport = report
    }

    /// Periodic background sync (`BGAppRefreshTask`). Features add their sync work here.
    func handleAppRefresh() async {
        AppLogger.lifecycle.info("background app refresh")
        refreshScheduler.scheduleAppRefresh()
    }
}
