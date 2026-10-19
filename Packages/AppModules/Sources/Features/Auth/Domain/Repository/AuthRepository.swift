/// Auth operations the domain needs. `AuthRepositoryImpl` (AuthData) is the only implementation; only the
/// app's `AuthContainer` names it (rule 4).
public protocol AuthRepository: Sendable {
    /// Signs in and keeps the session tokens; returns the user.
    func login(_ input: LoginInputEntity) async throws -> UserEntity
    /// Tells the backend to revoke the session. Local data is wiped separately by the session cleaner.
    func logout() async throws
    /// Exchanges a refresh token for a new pair. Does not store it: `TokenRefresher` does.
    func refresh(refreshToken: String) async throws -> AuthTokensEntity
}
