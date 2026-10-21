import SharedDomain

/// One page of the catalog, optionally filtered by a search query (blank queries mean no search).
public struct GetProductsUseCase: UseCase {
    private let repository: any CatalogRepository

    public init(repository: any CatalogRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ input: ProductListInputEntity) async throws -> PaginatedEntity<ProductEntity> {
        let query = input.query?.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await repository.products(
            ProductListInputEntity(query: query?.isEmpty == false ? query : nil, pagination: input.pagination))
    }
}
