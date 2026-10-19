import Core

public struct AuthRemoteDataSource: AuthDataSource {
    private let unauthenticatedClient: any HTTPClient
    private let authenticatedClient: any HTTPClient

    /// Login and refresh go through the client without the token interceptor; logout needs the token.
    public init(unauthenticatedClient: any HTTPClient, authenticatedClient: any HTTPClient) {
        self.unauthenticatedClient = unauthenticatedClient
        self.authenticatedClient = authenticatedClient
    }

    public func login(_ request: LoginRequest) async throws -> LoginResponse {
        try await unauthenticatedClient.send(AuthEndpoint.login(request))
    }

    public func refresh(_ request: RefreshRequest) async throws -> TokenResponse {
        try await unauthenticatedClient.send(AuthEndpoint.refresh(request))
    }

    public func logout() async throws {
        try await authenticatedClient.send(AuthEndpoint.logout)
    }
}
