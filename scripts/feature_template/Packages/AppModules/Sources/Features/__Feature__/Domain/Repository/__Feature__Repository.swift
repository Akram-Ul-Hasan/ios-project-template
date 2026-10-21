import SharedDomain

public protocol __Feature__Repository: Sendable {
    func items(_ pagination: PaginationInputEntity) async throws -> PaginatedEntity<__Feature__ItemEntity>
}
