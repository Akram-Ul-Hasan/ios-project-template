import SharedDomain
import Testing
import __Feature__Domain

@Suite("Get__Feature__ItemsUseCase")
struct Get__Feature__ItemsUseCaseTests {
    private struct Repository: __Feature__Repository {
        func items(_ pagination: PaginationInputEntity) async throws -> PaginatedEntity<__Feature__ItemEntity> {
            PaginatedEntity(
                items: [__Feature__ItemEntity(id: "1", title: "First")], page: pagination.page, hasNext: false)
        }
    }

    @Test("Returns the repository's page")
    func page() async throws {
        let page = try await Get__Feature__ItemsUseCase(repository: Repository())(
            PaginationInputEntity(page: 1, limit: 20))
        #expect(page.items.map(\.id) == ["1"])
    }
}
