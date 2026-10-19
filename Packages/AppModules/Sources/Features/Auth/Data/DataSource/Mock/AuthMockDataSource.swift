import Core

/// Development data from `App/Resources/Mock/auth/`. Any valid phone signs in; the password `wrong`
/// returns the API's 422 error body, so the error path can be exercised offline.
public struct AuthMockDataSource: AuthDataSource {
    private let mock: MockDataHelper
    private static let failingPassword = "wrong"

    public init(mock: MockDataHelper) {
        self.mock = mock
    }

    public func login(_ request: LoginRequest) async throws -> LoginResponse {
        if request.password == Self.failingPassword {
            let body: BackendError = try await mock.load("auth-login-error")
            throw ResponseError.from(statusCode: 422, body: body)
        }
        return try await mock.load("auth-login")
    }

    public func refresh(_ request: RefreshRequest) async throws -> TokenResponse {
        try await mock.load("auth-refresh")
    }

    public func logout() async throws {}
}
