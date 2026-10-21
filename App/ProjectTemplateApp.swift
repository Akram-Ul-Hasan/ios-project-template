import Core
import SwiftUI

@main
struct ProjectTemplateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        let container = appDelegate.container
        WindowGroup {
            if let container {
                RootView(container: container)
            } else {
                ConfigurationErrorView()
            }
        }
        .backgroundTask(.appRefresh(BackgroundTaskID.appRefresh)) {
            await container?.handleAppRefresh()
        }
    }
}
