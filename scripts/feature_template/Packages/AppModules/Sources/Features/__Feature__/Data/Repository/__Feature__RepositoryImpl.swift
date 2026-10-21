import Core
import SharedDomain
import __Feature__Domain
import os

public final class __Feature__RepositoryImpl: __Feature__Repository {
    private let dataSource: any __Feature__DataSource

    public init(factory: any __Feature__DataSourceFactory) {
        dataSource = factory.makeDataSource()
    }

    public func items(_ pagination: PaginationInputEntity) async throws -> PaginatedEntity<__Feature__ItemEntity> {
        let response = try await dataSource.items(page: pagination.page, limit: pagination.limit)
        do {
            return try response.toEntity()
        } catch {
            AppLogger.network.error("__feature_lower__ response broke the contract: \(error.detail, privacy: .public)")
            throw ResponseError.invalidResponse(detail: error.detail)
        }
    }
}
