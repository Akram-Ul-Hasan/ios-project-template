#if os(iOS)
    import BackgroundTasks
    import Foundation

    /// Periodic background work (§6n). The app refresh task is handled with SwiftUI's
    /// `.backgroundTask(.appRefresh(BackgroundTaskID.appRefresh))`; the cleanup processing task is registered here.
    /// Identifiers must be listed in Info.plist `BGTaskSchedulerPermittedIdentifiers`.
    public struct AppRefreshScheduler: Sendable {
        public init() {}

        /// Ask for the next refresh. Call at launch and at the end of every refresh run.
        public func scheduleAppRefresh(after interval: Duration = .seconds(15 * 60)) {
            let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskID.appRefresh)
            request.earliestBeginDate = Date.now.addingTimeInterval(TimeInterval(interval.components.seconds))
            submit(request)
        }

        /// Cache cleanup while charging, no network needed.
        public func scheduleCacheCleanup() {
            let request = BGProcessingTaskRequest(identifier: BackgroundTaskID.cacheCleanup)
            request.requiresExternalPower = true
            request.requiresNetworkConnectivity = false
            submit(request)
        }

        /// Must be called before the app finishes launching (AppDelegate `didFinishLaunching`).
        public func registerCacheCleanup(_ work: @escaping @Sendable () async -> Void) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundTaskID.cacheCleanup, using: nil) { task in
                let handle = TaskHandle(task: task)
                let job = Task {
                    await work()
                    handle.task.setTaskCompleted(success: !Task.isCancelled)
                }
                task.expirationHandler = { job.cancel() }
            }
        }

        private func submit(_ request: BGTaskRequest) {
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                // Expected on the simulator and when Background App Refresh is off.
                AppLogger.lifecycle.notice(
                    "BG task \(request.identifier, privacy: .public) not scheduled: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }

    /// BGTask isn't Sendable, but completing it from another thread is the documented usage.
    private struct TaskHandle: @unchecked Sendable {
        let task: BGTask
    }
#endif
