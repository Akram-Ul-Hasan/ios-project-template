import Core
import SharedDomain

/// Development data from `App/Resources/Mock/catalog/`: the full list is filtered and paged locally, so search
/// and infinite scroll behave like the real API.
public struct CatalogMockDataSource: CatalogDataSource {
    private let mock: MockDataHelper

    public init(mock: MockDataHelper) {
        self.mock = mock
    }

    public func products(page: Int, limit: Int, query: String?) async throws -> PaginatedResponse<ProductResponse> {
        let all: [ProductResponse] = try await mock.load("catalog-products")
        let matching = query.map { query in all.filter { $0.name.localizedStandardContains(query) } } ?? all
        let slice = mock.paginate(matching, input: PaginationInputEntity(page: page, limit: limit))
        return PaginatedResponse(items: slice.items, page: slice.page, hasNext: slice.hasNext)
    }

    public func productDetails(id: String) async throws -> ProductDetailsResponse {
        let all: [ProductResponse] = try await mock.load("catalog-products")
        guard let product = all.first(where: { $0.id == id }) else { throw ResponseError.notFound }
        let template: ProductDetailsTemplate = try await mock.load("catalog-product-details")
        return ProductDetailsResponse(
            id: product.id, name: product.name, price: product.price, discountPrice: product.discountPrice,
            imageUrl: product.imageUrl, tags: product.tags, status: product.status, description: template.description,
            images: [product.imageUrl, template.extraImageUrl].compactMap { $0 },
            stock: product.status == .outOfStock ? 0 : template.stock)
    }

    /// Shared details text for every mock product.
    private struct ProductDetailsTemplate: Decodable, Sendable {
        let description: String
        let extraImageUrl: String?
        let stock: Int
    }
}
