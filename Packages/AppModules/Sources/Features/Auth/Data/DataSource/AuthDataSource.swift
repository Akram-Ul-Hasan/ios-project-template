/// Where auth data comes from. Remote in staging/production, mock JSON in development (§5).
public protocol AuthDataSource: Sendable {
    func login(_ request: LoginRequest) async throws -> LoginResponse
    func refresh(_ request: RefreshRequest) async throws -> TokenResponse
    func logout() async throws
}
