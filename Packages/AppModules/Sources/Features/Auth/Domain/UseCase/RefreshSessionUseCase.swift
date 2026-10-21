import SharedDomain

/// Called by the app's token refresher when an access token expires.
public struct RefreshSessionUseCase: UseCase {
    private let repository: any AuthRepository

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ refreshToken: String) async throws -> AuthTokensEntity {
        try await repository.refresh(refreshToken: refreshToken)
    }
}
