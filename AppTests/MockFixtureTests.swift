import AuthData
import CatalogData
import CatalogDomain
import Core
import Testing

/// Fixtures decode through the same DTOs and mappers as real responses, so a broken fixture fails here (§3a).
/// Runs in the Development test host, the only build that contains `*.mock.json`.
@Suite("Mock fixtures")
@MainActor
struct MockFixtureTests {
    private let mock = MockDataHelper(latency: .zero)

    @Test("Auth fixtures decode and map")
    func auth() async throws {
        let source = AuthMockDataSource(mock: mock)
        let login = try await source.login(LoginRequest(phone: "01712345678", password: "secret"))
        _ = try login.toEntities()
        _ = try await source.refresh(RefreshRequest(refreshToken: "r")).toEntity()
        await #expect(throws: ResponseError.self) {
            try await source.login(LoginRequest(phone: "01712345678", password: "wrong"))
        }
    }

    @Test("Catalog fixtures decode, map, search and page")
    func catalog() async throws {
        let source = CatalogMockDataSource(mock: mock)
        let first = try await source.products(page: 1, limit: 20, query: nil)
        #expect(first.items.count == 20 && first.hasNext)
        _ = try first.toEntity()
        let last = try await source.products(page: 2, limit: 20, query: nil)
        #expect(last.items.count == 20 && !last.hasNext)
        let rice = try await source.products(page: 1, limit: 20, query: "rice")
        #expect(rice.items.count == 2)
        let details = try await source.productDetails(id: "p-001").toEntity()
        #expect(details.stock > 0 && !details.imageURLs.isEmpty)
        await #expect(throws: ResponseError.notFound) { try await source.productDetails(id: "missing") }
    }
}
