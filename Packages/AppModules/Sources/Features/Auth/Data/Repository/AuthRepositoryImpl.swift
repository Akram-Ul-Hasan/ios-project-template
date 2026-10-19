import AuthDomain
import Core
import os

public final class AuthRepositoryImpl: AuthRepository {
    private let dataSource: any AuthDataSource
    private let tokenStore: any TokenStore

    public init(factory: any AuthDataSourceFactory, tokenStore: any TokenStore) {
        dataSource = factory.makeAuthDataSource()
        self.tokenStore = tokenStore
    }

    public func login(_ input: LoginInputEntity) async throws -> UserEntity {
        let response = try await dataSource.login(LoginRequest(phone: input.phone, password: input.password))
        let (tokens, user) = try mapped { try response.toEntities() }
        try tokenStore.save(AuthTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken))
        AppLogger.auth.notice("signed in")
        return user
    }

    public func logout() async throws {
        try await dataSource.logout()
    }

    public func refresh(refreshToken: String) async throws -> AuthTokensEntity {
        let response = try await dataSource.refresh(RefreshRequest(refreshToken: refreshToken))
        return try mapped { try response.toEntity() }
    }

    /// Logs contract breaks (key path and reason, no values) so they're visible, then surfaces them as
    /// `invalidResponse` (§3a).
    private func mapped<T>(_ map: () throws -> T) throws -> T {
        do {
            return try map()
        } catch let error as MappingError {
            AppLogger.auth.error("auth response broke the contract: \(error.detail, privacy: .public)")
            throw ResponseError.invalidResponse(detail: error.detail)
        }
    }
}
