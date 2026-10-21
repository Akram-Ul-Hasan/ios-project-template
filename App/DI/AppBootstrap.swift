import Core
import Foundation
import os

extension AppContainer {
    /// Launch work that must not block the first frame (§6n): runs from `RootView`'s splash.
    func bootstrap() async {
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

    /// Periodic background sync (`BGAppRefreshTask`). Features add their sync work here.
    func handleAppRefresh() async {
        AppLogger.lifecycle.info("background app refresh")
        refreshScheduler.scheduleAppRefresh()
    }
}
