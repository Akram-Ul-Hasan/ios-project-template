import CatalogDomain
import Core
import SharedDomain
import os

/// Cache decorator (§11): wraps the remote repository. A successful first page (no search) refreshes the cache;
/// when offline, the cached page is served instead of an error. The container composes the two explicitly.
public final class CatalogCacheRepository: CatalogRepository {
    private let remote: any CatalogRepository
    private let local: CatalogLocalDataSource

    public init(remote: any CatalogRepository, local: CatalogLocalDataSource) {
        self.remote = remote
        self.local = local
    }

    public func products(_ input: ProductListInputEntity) async throws -> PaginatedEntity<ProductEntity> {
        guard input.pagination.page == 1, input.query == nil else { return try await remote.products(input) }
        do {
            let page = try await remote.products(input)
            do {
                try await local.replaceFirstPage(with: page.items)
            } catch {
                AppLogger.persistence.error(
                    "catalog cache write failed: \(error.localizedDescription, privacy: .public)")
            }
            return page
        } catch {
            guard ResponseError.from(error) == .network, let cached = try? await local.cachedFirstPage() else {
                throw error
            }
            AppLogger.network.notice("offline: serving cached catalog page")
            // Only the first page is cached, so there is nothing to page into while offline.
            return PaginatedEntity(items: cached, page: 1, hasNext: false)
        }
    }

    public func productDetails(id: String) async throws -> ProductDetailsEntity {
        try await remote.productDetails(id: id)
    }
}
