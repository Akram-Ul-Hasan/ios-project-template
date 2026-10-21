import SharedDomain

public struct GetProductDetailsUseCase: UseCase {
    private let repository: any CatalogRepository

    public init(repository: any CatalogRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ id: String) async throws -> ProductDetailsEntity {
        try await repository.productDetails(id: id)
    }
}
