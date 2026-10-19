import Core
import Observation
import os

/// Holds a link until the app can show it (§6c). A tap on a push at cold start arrives before any UI exists,
/// and a link that needs login waits until the user has signed in.
@MainActor
@Observable
final class DeepLinkHandler {
    private(set) var pending: DeepLink?

    @ObservationIgnored private let router: AppRouter
    @ObservationIgnored private var isReady = false
    @ObservationIgnored private var isSignedIn = false

    init(router: AppRouter) {
        self.router = router
    }

    /// From push taps, universal links and `onOpenURL`. `nil` (unrecognised link) is logged and ignored.
    func receive(_ link: DeepLink?) {
        guard let link else {
            AppLogger.navigation.notice("ignored unrecognised deep link")
            return
        }
        pending = link
        flush()
    }

    /// `RootView` calls this whenever its phase changes: ready = the tab UI is on screen.
    func update(isReady: Bool, isSignedIn: Bool) {
        self.isReady = isReady
        self.isSignedIn = isSignedIn
        flush()
    }

    private func flush() {
        guard isReady, let link = pending, isSignedIn || !link.requiresAuth else { return }
        pending = nil
        router.open(link)
    }
}
