import CatalogDomain
import Core
import SharedDomain
import os

public final class CatalogRepositoryImpl: CatalogRepository {
    private let dataSource: any CatalogDataSource

    public init(factory: any CatalogDataSourceFactory) {
        dataSource = factory.makeCatalogDataSource()
    }

    public func products(_ input: ProductListInputEntity) async throws -> PaginatedEntity<ProductEntity> {
        let response = try await dataSource.products(
            page: input.pagination.page, limit: input.pagination.limit, query: input.query)
        return try mapped { try response.toEntity() }
    }

    public func productDetails(id: String) async throws -> ProductDetailsEntity {
        let response = try await dataSource.productDetails(id: id)
        return try mapped { try response.toEntity() }
    }

    private func mapped<T>(_ map: () throws -> T) throws -> T {
        do {
            return try map()
        } catch let error as MappingError {
            AppLogger.network.error("catalog response broke the contract: \(error.detail, privacy: .public)")
            throw ResponseError.invalidResponse(detail: error.detail)
        }
    }
}
