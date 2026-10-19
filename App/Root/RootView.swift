import Core
import DesignSystem
import Localization
import SwiftUI

enum RootPhase: Equatable {
    case launching
    case onboarding
    case signedOut
    case signedIn
}

/// splash → onboarding → sign in → tabs. Also the root of the environment: language, theme, images, permissions.
struct RootView: View {
    let container: AppContainer
    @State private var phase: RootPhase = .launching

    var body: some View {
        content
            .animation(AppAnimation.standard, value: phase)
            .task { await launch() }
            .environment(container.networkMonitor)
            .environment(\.imagePipeline, container.imagePipeline)
            .environment(\.permissionManager, container.permissions)
            .environment(\.appFormatters, container.localization.formatters)
            .environment(\.locale, container.localization.locale)
            .environment(\.layoutDirection, container.localization.language.isRTL ? .rightToLeft : .leftToRight)
            // A language switch rebuilds the whole tree with the new strings, no restart needed (§6k).
            .id(container.localization.language)
            .preferredColorScheme(container.theme.colorScheme)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .launching:
            SplashView()
        case .onboarding:
            OnboardingPlaceholder {
                container.preferences.set(true, for: .onboardingSeen)
                phase = resolvedPhase()
            }
        case .signedOut:
            SignInPlaceholder(tokenStore: container.tokenStore) { phase = .signedIn }
        case .signedIn:
            MainTabView(container: container, router: container.router)
        }
    }

    private func launch() async {
        await container.bootstrap()
        phase = resolvedPhase()
    }

    private func resolvedPhase() -> RootPhase {
        if !container.preferences.value(.onboardingSeen) { return .onboarding }
        return container.tokenStore.tokens() == nil ? .signedOut : .signedIn
    }
}
