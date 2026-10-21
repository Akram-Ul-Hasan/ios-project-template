import CatalogDomain
import Core
import Foundation
import SharedDomain
import os

/// Serves `total` products, optionally filtered by query; can be switched to fail.
final class FakeCatalogRepository: CatalogRepository {
    private let total: Int
    let failure = OSAllocatedUnfairLock<ResponseError?>(initialState: nil)
    let queries = OSAllocatedUnfairLock<[String?]>(initialState: [])

    init(total: Int) { self.total = total }

    static func product(_ index: Int) -> ProductEntity {
        ProductEntity(
            id: "p\(index)", name: index.isMultiple(of: 2) ? "Rice \(index)" : "Oil \(index)", price: 100,
            discountPrice: nil, imageURL: nil, tags: [], status: .active)
    }

    func products(_ input: ProductListInputEntity) async throws -> PaginatedEntity<ProductEntity> {
        queries.withLock { $0.append(input.query) }
        if let error = failure.withLock({ $0 }) { throw error }
        let all = (0..<total).map(Self.product).filter { input.query == nil || $0.name.contains(input.query ?? "") }
        let start = (input.pagination.page - 1) * input.pagination.limit
        let end = min(all.count, start + input.pagination.limit)
        return PaginatedEntity(items: Array(all[start..<end]), page: input.pagination.page, hasNext: end < all.count)
    }

    func productDetails(id: String) async throws -> ProductDetailsEntity {
        if let error = failure.withLock({ $0 }) { throw error }
        return ProductDetailsEntity(product: Self.product(1), description: "Fresh", imageURLs: [], stock: 3)
    }
}
