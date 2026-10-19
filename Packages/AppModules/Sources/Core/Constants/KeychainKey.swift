/// Every Keychain item the app stores (§6g). Typed, never raw strings.
public enum KeychainKey: String, CaseIterable, Sendable {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case encryptionKey = "encryption_key"

    /// Items removed on logout. The encryption key survives so device-level encrypted files stay readable.
    public static let sessionKeys: [KeychainKey] = [.accessToken, .refreshToken]
}
