import SharedDomain

public struct Get__Feature__ItemsUseCase: UseCase {
    private let repository: any __Feature__Repository

    public init(repository: any __Feature__Repository) {
        self.repository = repository
    }

    public func callAsFunction(_ pagination: PaginationInputEntity) async throws -> PaginatedEntity<
        __Feature__ItemEntity
    > {
        try await repository.items(pagination)
    }
}
