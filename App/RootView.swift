import SwiftUI

/// Placeholder. Becomes splash → onboarding/login → MainTabView in the root-flow step.
struct RootView: View {
    let container: AppContainer

    var body: some View {
        Image(systemName: "swift")
            .font(.largeTitle)
            .foregroundStyle(.tint)
            .task { await container.bootstrap() }
    }
}
