import SharedDomain
import Testing
import os

@testable import Core

@Suite("PaginatedViewModel")
@MainActor
struct PaginatedViewModelTests {
    struct Row: Identifiable, Equatable, Sendable {
        let id: Int
    }

    /// Serves `total` rows in pages; `failing` pages throw; records every requested page.
    final class Server: Sendable {
        let total: Int
        let failing: OSAllocatedUnfairLock<Set<Int>>
        let requests = OSAllocatedUnfairLock<[Int]>(initialState: [])
        let offset = OSAllocatedUnfairLock(initialState: 0)

        init(total: Int, failing: Set<Int> = []) {
            self.total = total
            self.failing = OSAllocatedUnfairLock(initialState: failing)
        }

        func fetch(_ input: PaginationInputEntity) async throws -> PaginatedEntity<Row> {
            requests.withLock { $0.append(input.page) }
            try await Task.sleep(for: .milliseconds(5))
            if failing.withLock({ $0.contains(input.page) }) { throw ResponseError.server(statusCode: 500) }
            let start = (input.page - 1) * input.limit
            let end = min(total, start + input.limit)
            let shift = offset.withLock { $0 }
            let rows = start < end ? (start..<end).map { Row(id: $0 + shift) } : []
            return PaginatedEntity(items: rows, page: input.page, hasNext: end < total)
        }
    }

    private func model(_ server: Server) -> PaginatedViewModel<Row> {
        PaginatedViewModel(pageSize: 10) { try await server.fetch($0) }
    }

    @Test("First page loads; an empty result is .empty; a failure is .failure")
    func firstPage() async {
        let loaded = model(Server(total: 25))
        await loaded.loadFirst()
        #expect(loaded.items.count == 10 && loaded.phase == .loaded && loaded.hasNext)

        let empty = model(Server(total: 0))
        await empty.loadFirst()
        #expect(empty.phase == .empty)

        let failing = model(Server(total: 25, failing: [1]))
        await failing.loadFirst()
        #expect(failing.phase == .failure(.server(statusCode: 500)))
    }

    @Test("Loads more only near the end, and stops at the last page")
    func loadMore() async {
        let server = Server(total: 25)
        let model = model(server)
        await model.loadFirst()
        await model.loadMoreIfNeeded(currentItem: model.items[0])
        #expect(model.items.count == 10)
        await model.loadMoreIfNeeded(currentItem: model.items[6])
        await model.loadMoreIfNeeded(currentItem: model.items[19])
        #expect(model.items.count == 25 && !model.hasNext)
        await model.loadMoreIfNeeded(currentItem: model.items[24])
        #expect(server.requests.withLock { $0 } == [1, 2, 3])
    }

    @Test("Concurrent triggers fetch a page only once")
    func noDoubleLoad() async {
        let server = Server(total: 50)
        let model = model(server)
        await model.loadFirst()
        let last = model.items[9]
        async let first: Void = model.loadMoreIfNeeded(currentItem: last)
        async let second: Void = model.loadMoreIfNeeded(currentItem: last)
        _ = await (first, second)
        #expect(server.requests.withLock { $0 } == [1, 2])
    }

    @Test("A failed next page keeps the items and can be retried")
    func failureMore() async {
        let server = Server(total: 25, failing: [2])
        let model = model(server)
        await model.loadFirst()
        await model.loadMoreIfNeeded(currentItem: model.items[9])
        #expect(model.phase == .failureMore(.server(statusCode: 500)) && model.items.count == 10)

        server.failing.withLock { $0 = [] }
        await model.retryMore()
        #expect(model.phase == .loaded && model.items.count == 20)
    }

    @Test("Refresh swaps in page 1 at once; a failed refresh throws and keeps the old items")
    func refresh() async throws {
        let server = Server(total: 25)
        let model = model(server)
        await model.loadFirst()
        await model.loadMoreIfNeeded(currentItem: model.items[9])

        server.offset.withLock { $0 = 100 }
        try await model.refresh()
        #expect(model.items.map(\.id) == Array(100..<110))

        server.failing.withLock { $0 = [1] }
        await #expect(throws: ResponseError.server(statusCode: 500)) { try await model.refresh() }
        #expect(model.items.map(\.id) == Array(100..<110))
        #expect(!model.isRefreshing)
    }

    @Test("Refreshing after a failed first load starts again")
    func refreshAfterFailure() async throws {
        let server = Server(total: 5, failing: [1])
        let model = model(server)
        await model.loadFirst()
        server.failing.withLock { $0 = [] }
        try await model.refresh()
        #expect(model.phase == .loaded && model.items.count == 5)
    }
}
