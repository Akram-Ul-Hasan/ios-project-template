import LocalAuthentication

/// Face ID / Touch ID behind a protocol so `SessionManager` is testable. Needs `NSFaceIDUsageDescription`.
public protocol BiometricAuthenticating: Sendable {
    var isAvailable: Bool { get }
    /// Falls back to the device passcode when biometrics fail or aren't enrolled.
    func authenticate(reason: String) async -> Bool
}

public struct BiometricAuthService: BiometricAuthenticating {
    public init() {}

    public var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    public func authenticate(reason: String) async -> Bool {
        do {
            return try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            AppLogger.security.notice(
                "biometric authentication failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
