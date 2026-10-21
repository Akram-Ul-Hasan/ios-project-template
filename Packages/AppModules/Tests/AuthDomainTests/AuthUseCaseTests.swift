import AuthDomain
import SharedDomain
import Testing

@Suite("Auth use cases")
struct AuthUseCaseTests {
    @Test("Login validates before calling the repository")
    func loginValidates() async {
        let repository = MockAuthRepository()
        let login = LoginUseCase(repository: repository)

        await #expect(throws: DomainError.validation(field: "phone", error: .invalidFormat(.phone))) {
            try await login(LoginInputEntity(phone: "123", password: "secret"))
        }
        await #expect(throws: DomainError.validation(field: "password", error: .required)) {
            try await login(LoginInputEntity(phone: "01712345678", password: " "))
        }
        #expect(repository.recorded.isEmpty)
    }

    @Test("Valid input signs in through the repository")
    func loginSucceeds() async throws {
        let repository = MockAuthRepository()
        let user = try await LoginUseCase(repository: repository)(LoginInputEntity(phone: "01712345678", password: "x"))
        #expect(user == .sample)
        #expect(repository.recorded == ["login:01712345678"])
    }

    @Test("Logout never fails, even when the backend call does")
    func logoutIsBestEffort() async throws {
        struct Offline: Error {}
        let repository = MockAuthRepository(logoutError: Offline())
        try await LogoutUseCase(repository: repository)()
        #expect(repository.recorded == ["logout"])
    }

    @Test("Refresh passes the refresh token through")
    func refresh() async throws {
        let repository = MockAuthRepository()
        let tokens = try await RefreshSessionUseCase(repository: repository)("r0")
        #expect(tokens.accessToken == "a")
        #expect(repository.recorded == ["refresh:r0"])
    }
}
