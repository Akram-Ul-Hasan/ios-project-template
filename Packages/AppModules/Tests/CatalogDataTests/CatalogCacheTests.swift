import CatalogData
import CatalogDomain
import Core
import CoreData
import Foundation
import SharedDomain
import Testing
import os

@Suite("Catalog cache")
struct CatalogCacheTests {
    private static func product(_ id: String, status: ProductStatus = .active) -> ProductEntity {
        ProductEntity(
            id: id, name: "Product \(id)", price: Decimal(string: "450.50")!, discountPrice: id == "1" ? 399 : nil,
            imageURL: URL(string: "https://cdn.test/\(id).jpg"), tags: id == "1" ? ["popular", "new"] : [],
            status: status)
    }

    private func makePersistence() async throws -> PersistenceController {
        let model = try #require(CatalogDataModel.load())
        let persistence = PersistenceController(name: "CatalogTests", models: [model], location: .inMemory)
        try await persistence.load()
        return persistence
    }

    /// Remote that returns a page or fails, and counts calls.
    private final class Remote: CatalogRepository {
        let result: Result<PaginatedEntity<ProductEntity>, ResponseError>
        let calls = OSAllocatedUnfairLock(initialState: 0)
        init(_ result: Result<PaginatedEntity<ProductEntity>, ResponseError>) { self.result = result }
        func products(_ input: ProductListInputEntity) async throws -> PaginatedEntity<ProductEntity> {
            calls.withLock { $0 += 1 }
            return try result.get()
        }
        func productDetails(id: String) async throws -> ProductDetailsEntity { throw ResponseError.notFound }
    }

    private let firstPage = ProductListInputEntity(query: nil, pagination: PaginationInputEntity(page: 1, limit: 20))

    @Test("Round-trips products exactly, in order, including money, tags and unknown statuses")
    func roundTrip() async throws {
        let local = CatalogLocalDataSource(persistence: try await makePersistence())
        let products = [Self.product("1"), Self.product("2", status: .unknown("pre_order")), Self.product("3")]
        try await local.replaceFirstPage(with: products)
        #expect(try await local.cachedFirstPage() == products)
        try await local.replaceFirstPage(with: [Self.product("9")])
        #expect(try await local.cachedFirstPage() == [Self.product("9")])
    }

    @Test("An empty cache is a miss; a corrupted row wipes the cache and is a miss too")
    func corrupted() async throws {
        let persistence = try await makePersistence()
        let local = CatalogLocalDataSource(persistence: persistence)
        #expect(try await local.cachedFirstPage() == nil)

        try await local.replaceFirstPage(with: [Self.product("1")])
        let context = persistence.container.newBackgroundContext()
        try await context.perform {
            let broken = NSEntityDescription.insertNewObject(forEntityName: "ProductDBModel", into: context)
            broken.setValue("x", forKey: "id")  // no name, price or status
            try context.save()
        }
        #expect(try await local.cachedFirstPage() == nil)
        #expect(try await local.cachedFirstPage() == nil)
    }

    @Test("Online: the first page refreshes the cache")
    func onlineWritesCache() async throws {
        let local = CatalogLocalDataSource(persistence: try await makePersistence())
        let page = PaginatedEntity(items: [Self.product("1")], page: 1, hasNext: true)
        let repository = CatalogCacheRepository(remote: Remote(.success(page)), local: local)
        #expect(try await repository.products(firstPage) == page)
        #expect(try await local.cachedFirstPage() == [Self.product("1")])
    }

    @Test("Offline: the cached page is served, with no next page")
    func offlineServesCache() async throws {
        let local = CatalogLocalDataSource(persistence: try await makePersistence())
        try await local.replaceFirstPage(with: [Self.product("1")])
        let repository = CatalogCacheRepository(remote: Remote(.failure(.network)), local: local)
        #expect(
            try await repository.products(firstPage)
                == PaginatedEntity(items: [Self.product("1")], page: 1, hasNext: false))
    }

    @Test("Offline with no cache, or a non-network error, still fails")
    func failures() async throws {
        let local = CatalogLocalDataSource(persistence: try await makePersistence())
        await #expect(throws: ResponseError.network) {
            try await CatalogCacheRepository(remote: Remote(.failure(.network)), local: local).products(firstPage)
        }
        try await local.replaceFirstPage(with: [Self.product("1")])
        await #expect(throws: ResponseError.server(statusCode: 500)) {
            try await CatalogCacheRepository(remote: Remote(.failure(.server(statusCode: 500))), local: local).products(
                firstPage)
        }
    }

    @Test("Searches and later pages bypass the cache")
    func passThrough() async throws {
        let local = CatalogLocalDataSource(persistence: try await makePersistence())
        try await local.replaceFirstPage(with: [Self.product("1")])
        let repository = CatalogCacheRepository(remote: Remote(.failure(.network)), local: local)
        await #expect(throws: ResponseError.network) {
            try await repository.products(
                ProductListInputEntity(query: "rice", pagination: PaginationInputEntity(page: 1, limit: 20)))
        }
        await #expect(throws: ResponseError.network) {
            try await repository.products(
                ProductListInputEntity(query: nil, pagination: PaginationInputEntity(page: 2, limit: 20)))
        }
    }
}
