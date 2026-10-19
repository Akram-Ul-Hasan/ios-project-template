import Core
import DesignSystem
import Foundation
import os

/// The composition root (§6): creates every long-lived object once and hands them to feature containers.
/// Only the app target knows all features; features never import `App`.
@MainActor
final class AppContainer {
    let env: Env

    // Storage
    let preferences: UserDefaultsPreferencesStore
    let keychain: any KeychainStoring
    let tokenStore: SecureTokenStore
    let encryptedFiles: EncryptedFileStore?
    let persistence: PersistenceController

    // Networking
    let unauthenticatedClient: any HTTPClient
    let authenticatedClient: any HTTPClient
    let tokenRefreshBridge = TokenRefreshBridge()
    let mockData = MockDataHelper()

    // Navigation
    let router: AppRouter
    let deepLinks: DeepLinkHandler

    // Session, feedback, app-wide UI state
    let sessionEvents = SessionEvents()
    let sessionManager: SessionManager
    let feedback = FeedbackCenter()
    let errorHandler: ErrorHandler
    let networkMonitor = NetworkMonitor()
    let localization: LocalizationManager
    let theme: ThemeManager
    let permissions: any PermissionManager = SystemPermissionManager()
    let imagePipeline: ImagePipeline?
    let pushPermission: PushPermissionService
    /// Latest APNs token; the notification feature sends it to the backend.
    var apnsToken: String?

    // Diagnostics and background work
    let metrics: MetricsCollector
    let refreshScheduler = AppRefreshScheduler()

    private static let biometricLockTimeout: Duration = .seconds(5 * 60)

    init(env: Env) {
        self.env = env
        router = AppRouter()
        deepLinks = DeepLinkHandler(router: router)
        preferences = UserDefaultsPreferencesStore()
        keychain = KeychainService(accessGroup: nil)
        tokenStore = SecureTokenStore(keychain: keychain)
        Self.wipeKeychainOnFirstLaunch(preferences: preferences, keychain: keychain)

        // Every one of these is optional on purpose: a failure degrades a feature, it never crashes the app.
        encryptedFiles = Self.makeEncryptedFileStore(keychain: keychain)
        imagePipeline = try? ImagePipeline.makeDefault()
        persistence = PersistenceController(name: "ProjectTemplate", models: [], location: .onDisk)

        let refresher = TokenRefresher(store: tokenStore, events: sessionEvents) { [tokenRefreshBridge] token in
            try await tokenRefreshBridge.refresh(token)
        }
        let session = URLSessionHTTPClient.makeSession()
        let log = NetworkLogInterceptor(enabled: env.isDiagnosticsEnabled)
        unauthenticatedClient = URLSessionHTTPClient(
            baseURL: env.baseURL, session: session,
            interceptors: [log, LanguageInterceptor(), BackendErrorInterceptor()])
        authenticatedClient = URLSessionHTTPClient(
            baseURL: env.baseURL, session: session,
            interceptors: [
                log, AuthTokenInterceptor(store: tokenStore, refresher: refresher), LanguageInterceptor(),
                BackendErrorInterceptor(),
            ])

        localization = LocalizationManager(preferences: preferences)
        theme = ThemeManager(preferences: preferences)
        errorHandler = ErrorHandler(feedback: feedback, events: sessionEvents)

        var cleanables: [any SessionCleanable] = [tokenStore, preferences, persistence]
        if let encryptedFiles { cleanables.append(encryptedFiles) }
        if let imagePipeline { cleanables.append(imagePipeline) }
        sessionManager = SessionManager(
            cleaner: SessionCleaner(cleanables: cleanables), events: sessionEvents,
            biometrics: BiometricAuthService(), lockTimeout: Self.biometricLockTimeout)

        pushPermission = PushPermissionService(permissions: permissions)
        metrics = MetricsCollector(upload: nil)
    }

    /// The Keychain survives app deletion: on the first launch after an install, old tokens must not log anyone in.
    private static func wipeKeychainOnFirstLaunch(preferences: any PreferencesStore, keychain: any KeychainStoring) {
        guard !preferences.value(.hasLaunchedBefore) else { return }
        try? keychain.remove(KeychainKey.allCases)
        preferences.set(true, for: .hasLaunchedBefore)
        AppLogger.security.notice("first launch: cleared stale Keychain items")
    }

    private static func makeEncryptedFileStore(keychain: any KeychainStoring) -> EncryptedFileStore? {
        do {
            return EncryptedFileStore(
                directory: try EncryptedFileStore.defaultDirectory(),
                encryption: try AESGCMEncryptionManager(keychain: keychain))
        } catch {
            AppLogger.security.fault(
                "encrypted file store unavailable: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
