import CatalogDomain
import SharedDomain
import Testing
import os

@Suite("Catalog use cases")
struct CatalogUseCaseTests {
    private final class Repository: CatalogRepository {
        let inputs = OSAllocatedUnfairLock<[ProductListInputEntity]>(initialState: [])
        func products(_ input: ProductListInputEntity) async throws -> PaginatedEntity<ProductEntity> {
            inputs.withLock { $0.append(input) }
            return PaginatedEntity(items: [], page: input.pagination.page, hasNext: false)
        }
        func productDetails(id: String) async throws -> ProductDetailsEntity {
            ProductDetailsEntity(
                product: ProductEntity(
                    id: id, name: "P", price: 1, discountPrice: nil, imageURL: nil, tags: [], status: .active),
                description: "", imageURLs: [], stock: 1)
        }
    }

    @Test(
        "Blank search queries mean no search; real ones are trimmed",
        arguments: [("  ", nil), ("", nil), (" rice ", "rice"), (nil, nil)] as [(String?, String?)])
    func queries(raw: String?, expected: String?) async throws {
        let repository = Repository()
        let page = PaginationInputEntity(page: 1, limit: 20)
        _ = try await GetProductsUseCase(repository: repository)(ProductListInputEntity(query: raw, pagination: page))
        #expect(repository.inputs.withLock { $0.first?.query } == expected)
    }

    @Test("Details pass the id through")
    func details() async throws {
        #expect(try await GetProductDetailsUseCase(repository: Repository())("p9").product.id == "p9")
    }
}
