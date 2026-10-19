import Foundation
import SharedDomain
import Testing

@testable import Core

@Suite("MockDataHelper")
struct MockDataHelperTests {
    private struct Item: Decodable, Equatable, Sendable {
        let id: Int
    }

    private struct Named: Decodable, Sendable {
        let name: String
    }

    private let mock = MockDataHelper(bundle: .module, latency: .zero)

    @Test("Loads a fixture from Mock/<feature>/<name>.json")
    func load() async throws {
        let items: [Item] = try await mock.load("catalog/items")
        #expect(items.map(\.id) == [1, 2, 3, 4, 5])
    }

    @Test("A fixture that breaks the DTO fails like a real response")
    func broken() async {
        await #expect(throws: ResponseError.invalidResponse(detail: "expected String at name")) {
            let _: Named = try await mock.load("catalog/broken")
        }
    }

    @Test("A missing fixture throws")
    func missing() async {
        await #expect(throws: ResponseError.invalidResponse(detail: "missing fixture catalog/nope")) {
            let _: [Item] = try await mock.load("catalog/nope")
        }
    }

    @Test(
        "Pages through a list",
        arguments: [
            (1, [1, 2], true), (2, [3, 4], true), (3, [5], false), (4, [], false),
        ])
    func paginate(page: Int, ids: [Int], hasNext: Bool) {
        let result = mock.paginate(Array(1...5), input: PaginationInputEntity(page: page, limit: 2))
        #expect(result == PaginatedEntity(items: ids, page: page, hasNext: hasNext))
    }
}
