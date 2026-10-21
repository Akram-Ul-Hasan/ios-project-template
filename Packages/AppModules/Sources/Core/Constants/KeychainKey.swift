/// Every Keychain item the app stores (§6g). Typed, never raw strings.
public enum KeychainKey: String, CaseIterable, Sendable {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case encryptionKey = "encryption_key"
    /// App Attest key id; device-bound, survives logout.
    case appAttestKeyID = "app_attest_key_id"

    /// Items removed on logout. Device-level keys (encryption, App Attest) survive.
    public static let sessionKeys: [KeychainKey] = [.accessToken, .refreshToken]
}
