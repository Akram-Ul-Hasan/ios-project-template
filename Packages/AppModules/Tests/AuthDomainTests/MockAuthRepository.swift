import AuthDomain
import os

/// Records calls and returns canned results.
final class MockAuthRepository: AuthRepository {
    let loginResult: Result<UserEntity, any Error>
    let refreshResult: Result<AuthTokensEntity, any Error>
    let logoutError: (any Error)?
    private let calls = OSAllocatedUnfairLock<[String]>(initialState: [])

    init(
        loginResult: Result<UserEntity, any Error> = .success(.sample),
        refreshResult: Result<AuthTokensEntity, any Error> = .success(
            AuthTokensEntity(accessToken: "a", refreshToken: "r")),
        logoutError: (any Error)? = nil
    ) {
        self.loginResult = loginResult
        self.refreshResult = refreshResult
        self.logoutError = logoutError
    }

    var recorded: [String] { calls.withLock { $0 } }

    func login(_ input: LoginInputEntity) async throws -> UserEntity {
        calls.withLock { $0.append("login:\(input.phone)") }
        return try loginResult.get()
    }

    func logout() async throws {
        calls.withLock { $0.append("logout") }
        if let logoutError { throw logoutError }
    }

    func refresh(refreshToken: String) async throws -> AuthTokensEntity {
        calls.withLock { $0.append("refresh:\(refreshToken)") }
        return try refreshResult.get()
    }
}

extension UserEntity {
    static let sample = UserEntity(id: "u1", name: "Rahim", phone: "01712345678", email: nil, avatarURL: nil)
}
