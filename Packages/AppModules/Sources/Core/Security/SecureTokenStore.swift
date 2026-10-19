import Foundation

public struct AuthTokens: Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

/// Session tokens. They live only here (rule 19); `AuthTokenInterceptor` reads them, login and refresh write them.
public protocol TokenStore: Sendable {
    func tokens() -> AuthTokens?
    func save(_ tokens: AuthTokens) throws
    func clear() throws
}

public struct SecureTokenStore: TokenStore {
    private let keychain: any KeychainStoring

    public init(keychain: any KeychainStoring) {
        self.keychain = keychain
    }

    public func tokens() -> AuthTokens? {
        do {
            guard let access = try keychain.data(for: .accessToken),
                let refresh = try keychain.data(for: .refreshToken)
            else { return nil }
            return AuthTokens(
                accessToken: String(decoding: access, as: UTF8.self),
                refreshToken: String(decoding: refresh, as: UTF8.self))
        } catch {
            AppLogger.security.error("token read failed: \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    public func save(_ tokens: AuthTokens) throws {
        try keychain.set(Data(tokens.accessToken.utf8), for: .accessToken)
        try keychain.set(Data(tokens.refreshToken.utf8), for: .refreshToken)
    }

    public func clear() throws {
        try keychain.remove(KeychainKey.sessionKeys)
    }
}
