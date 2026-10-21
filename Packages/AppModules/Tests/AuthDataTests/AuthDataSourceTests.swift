import AuthData
import Core
import TestSupport
import Testing

@Suite("Auth data sources")
struct AuthDataSourceTests {
    @Test("Login and refresh use the unauthenticated client, logout the authenticated one")
    func clients() async throws {
        let open = MockHTTPClient()
        let secured = MockHTTPClient()
        open.stub(
            "/v1/auth/login",
            json: #"{"access_token":"a","refresh_token":"r","user":{"id":"1","name":"R","phone":"0"}}"#)
        open.stub("/v1/auth/refresh", json: #"{"access_token":"a2","refresh_token":"r2"}"#)
        secured.stub("/v1/auth/logout", json: "{}")
        let source = AuthRemoteDataSource(unauthenticatedClient: open, authenticatedClient: secured)

        _ = try await source.login(LoginRequest(phone: "0", password: "p"))
        _ = try await source.refresh(RefreshRequest(refreshToken: "r"))
        try await source.logout()
        #expect(open.sentPaths == ["/v1/auth/login", "/v1/auth/refresh"])
        #expect(secured.sentPaths == ["/v1/auth/logout"])
    }

    @Test("Endpoints that obtain tokens don't require one")
    func requiresAuth() {
        #expect(!AuthEndpoint.login(LoginRequest(phone: "0", password: "p")).requiresAuth)
        #expect(!AuthEndpoint.refresh(RefreshRequest(refreshToken: "r")).requiresAuth)
        #expect(AuthEndpoint.logout.requiresAuth)
    }
}
