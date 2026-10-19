import Localization
import Observation

/// Owns the signed-in session's lifecycle: biometric re-lock after time in the background, and logout.
@MainActor
@Observable
public final class SessionManager {
    /// `RootView` covers the app with a lock screen while this is true.
    public private(set) var isLocked = false
    /// Turned on from settings; only effective when biometrics are available.
    public var isBiometricLockEnabled = false

    @ObservationIgnored private let cleaner: SessionCleaner
    @ObservationIgnored private let events: SessionEvents
    @ObservationIgnored private let biometrics: any BiometricAuthenticating
    @ObservationIgnored private let lockTimeout: Duration
    @ObservationIgnored private var backgroundedAt: ContinuousClock.Instant?

    public init(
        cleaner: SessionCleaner,
        events: SessionEvents,
        biometrics: any BiometricAuthenticating,
        lockTimeout: Duration
    ) {
        self.cleaner = cleaner
        self.events = events
        self.biometrics = biometrics
        self.lockTimeout = lockTimeout
    }

    public func didEnterBackground(at now: ContinuousClock.Instant = .now) {
        backgroundedAt = now
    }

    public func willEnterForeground(at now: ContinuousClock.Instant = .now) {
        defer { backgroundedAt = nil }
        guard isBiometricLockEnabled, biometrics.isAvailable, let backgroundedAt else { return }
        if backgroundedAt.duration(to: now) >= lockTimeout { isLocked = true }
    }

    @discardableResult
    public func unlock() async -> Bool {
        guard isLocked else { return true }
        let success = await biometrics.authenticate(reason: L10n.Session.unlockReason)
        if success { isLocked = false }
        return success
    }

    /// Wipes all user data, then tells `RootView` to show login.
    public func logout() async {
        await cleaner.clean()
        isLocked = false
        AppLogger.auth.notice("logged out")
        events.send(.loggedOut)
    }
}
