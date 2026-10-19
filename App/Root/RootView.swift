import Core
import DesignSystem
import Localization
import SwiftUI

enum RootPhase: Equatable {
    case launching
    case onboarding
    case signedOut
    case signedIn
    case blocked(SessionEvent)
}

/// splash → onboarding → sign in → tabs. Also the root of the environment: language, theme, images, permissions.
struct RootView: View {
    let container: AppContainer
    @State private var phase: RootPhase = .launching
    @State private var isLoggingOut = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        content
            .sessionLock(container.sessionManager, isActive: phase == .signedIn)
            .privacyScreen()
            .animation(AppAnimation.standard, value: phase)
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background: container.sessionManager.didEnterBackground()
                case .active: container.sessionManager.willEnterForeground()
                default: break
                }
            }
            .task { await launch() }
            .task { await observeSessionEvents() }
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
        case .blocked(let event):
            BlockingView(event: event) { phase = resolvedPhase() }
        }
    }

    private func launch() async {
        await container.bootstrap()
        phase = resolvedPhase()
    }

    /// App-level events from anywhere (token refresh, `ErrorHandling`, logout) land here.
    private func observeSessionEvents() async {
        for await event in container.sessionEvents.stream() {
            switch event {
            case .sessionExpired:
                // Idempotent: several failing requests may report the same expiry.
                guard phase == .signedIn, !isLoggingOut else { continue }
                isLoggingOut = true
                await container.sessionManager.logout()
                isLoggingOut = false
            case .loggedOut:
                container.router.reset()
                if phase == .signedIn { phase = .signedOut }
            case .maintenance, .updateRequired:
                phase = .blocked(event)
            }
        }
    }

    private func resolvedPhase() -> RootPhase {
        if !container.preferences.value(.onboardingSeen) { return .onboarding }
        return container.tokenStore.tokens() == nil ? .signedOut : .signedIn
    }
}
