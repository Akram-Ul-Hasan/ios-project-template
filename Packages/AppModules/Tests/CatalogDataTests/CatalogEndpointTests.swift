import CatalogData
import Core
import Foundation
import Testing

@Suite("CatalogEndpoint")
struct CatalogEndpointTests {
    @Test("Products send page, limit and the optional query")
    func query() throws {
        let base = try #require(URL(string: "https://api.test"))
        let search = try CatalogEndpoint.products(page: 2, limit: 20, query: "rice").makeRequest(
            baseURL: base, encoder: .app)
        #expect(search.url?.absoluteString == "https://api.test/v1/products?page=2&limit=20&q=rice")
        let all = try CatalogEndpoint.products(page: 1, limit: 20, query: nil).makeRequest(baseURL: base, encoder: .app)
        #expect(all.url?.absoluteString == "https://api.test/v1/products?page=1&limit=20")
        #expect(!CatalogEndpoint.productDetails(id: "p1").requiresAuth)
    }
}
