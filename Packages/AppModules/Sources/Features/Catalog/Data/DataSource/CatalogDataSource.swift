public protocol CatalogDataSource: Sendable {
    func products(page: Int, limit: Int, query: String?) async throws -> PaginatedResponse<ProductResponse>
    func productDetails(id: String) async throws -> ProductDetailsResponse
}
