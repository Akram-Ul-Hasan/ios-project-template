import SharedDomain

/// Revokes the session on the backend. Best effort: logging out must work offline too,
/// so failures are swallowed here and local data is wiped regardless.
public struct LogoutUseCase: UseCase {
    private let repository: any AuthRepository

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ input: Void) async throws {
        try? await repository.logout()
    }
}
