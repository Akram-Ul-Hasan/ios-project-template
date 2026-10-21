import AuthData
import AuthDomain
import Core
import Foundation
import TestSupport
import Testing

@Suite("AuthRepositoryImpl")
struct AuthRepositoryTests {
    private struct Source: AuthDataSource {
        var login: LoginResponseJSON = .valid
        func login(_ request: LoginRequest) async throws -> LoginResponse {
            try JSONDecoder.app.decode(LoginResponse.self, from: Data(login.rawValue.utf8))
        }
        func refresh(_ request: RefreshRequest) async throws -> TokenResponse {
            try JSONDecoder.app.decode(
                TokenResponse.self, from: Data(#"{"access_token":"a2","refresh_token":"r2"}"#.utf8))
        }
        func logout() async throws {}
    }

    enum LoginResponseJSON: String {
        case valid = #"{"access_token":"a1","refresh_token":"r1","user":{"id":"u1","name":"R","phone":"017"}}"#
        case brokenUser = #"{"access_token":"a1","refresh_token":"r1","user":{"id":"","name":"R","phone":"017"}}"#
    }

    private struct Factory: AuthDataSourceFactory {
        let source: Source
        func makeAuthDataSource() -> any AuthDataSource { source }
    }

    private let tokenStore = SecureTokenStore(keychain: InMemoryKeychain())

    @Test("Login keeps the tokens and returns the user")
    func login() async throws {
        let repository = AuthRepositoryImpl(factory: Factory(source: Source()), tokenStore: tokenStore)
        let user = try await repository.login(LoginInputEntity(phone: "017", password: "p"))
        #expect(user.id == "u1")
        #expect(tokenStore.tokens() == AuthTokens(accessToken: "a1", refreshToken: "r1"))
    }

    @Test("A response that breaks the contract is an error, and no session is stored")
    func brokenContract() async {
        let repository = AuthRepositoryImpl(
            factory: Factory(source: Source(login: .brokenUser)), tokenStore: tokenStore)
        await #expect(throws: ResponseError.invalidResponse(detail: "user.id: empty")) {
            try await repository.login(LoginInputEntity(phone: "017", password: "p"))
        }
        #expect(tokenStore.tokens() == nil)
    }

    @Test("Refresh maps the new pair without storing it")
    func refresh() async throws {
        let repository = AuthRepositoryImpl(factory: Factory(source: Source()), tokenStore: tokenStore)
        #expect(
            try await repository.refresh(refreshToken: "r1") == AuthTokensEntity(accessToken: "a2", refreshToken: "r2"))
        #expect(tokenStore.tokens() == nil)
    }
}
