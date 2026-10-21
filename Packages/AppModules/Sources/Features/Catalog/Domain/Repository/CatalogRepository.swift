import SharedDomain

public protocol CatalogRepository: Sendable {
    func products(_ input: ProductListInputEntity) async throws -> PaginatedEntity<ProductEntity>
    func productDetails(id: String) async throws -> ProductDetailsEntity
}
