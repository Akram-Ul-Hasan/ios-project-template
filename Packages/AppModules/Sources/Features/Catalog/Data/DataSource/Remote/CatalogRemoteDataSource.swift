import Core

public struct CatalogRemoteDataSource: CatalogDataSource {
    private let client: any HTTPClient

    public init(client: any HTTPClient) {
        self.client = client
    }

    public func products(page: Int, limit: Int, query: String?) async throws -> PaginatedResponse<ProductResponse> {
        try await client.send(CatalogEndpoint.products(page: page, limit: limit, query: query))
    }

    public func productDetails(id: String) async throws -> ProductDetailsResponse {
        try await client.send(CatalogEndpoint.productDetails(id: id))
    }
}
