import SwiftUI

/// Placeholder. Becomes splash → onboarding/login → MainTabView in the root-flow step.
struct RootView: View {
    let container: AppContainer

    var body: some View {
        MainTabView(container: container, router: container.router)
            .task { await container.bootstrap() }
    }
}
