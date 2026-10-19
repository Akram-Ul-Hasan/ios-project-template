import Observation
import SharedDomain

/// The paging engine every list uses (§6e, BasePaginationCubit equivalent). A feature view model owns one:
/// `let products = PaginatedViewModel { try await search(.init(query: q, pagination: $0)) }`
/// and `PaginatedList` renders it.
@MainActor
@Observable
public final class PaginatedViewModel<Item: Identifiable & Equatable & Sendable> {
    public typealias Fetch = @Sendable (PaginationInputEntity) async throws -> PaginatedEntity<Item>

    public private(set) var items: [Item] = []
    public private(set) var phase: PaginationPhase = .idle
    public private(set) var isRefreshing = false
    public private(set) var hasNext = true

    @ObservationIgnored private var page = 0
    @ObservationIgnored private let pageSize: Int
    @ObservationIgnored private let fetch: Fetch
    /// Start loading the next page when this close to the end.
    @ObservationIgnored private let prefetchDistance = 5

    public init(pageSize: Int = NetworkConstants.defaultPageSize, fetch: @escaping Fetch) {
        self.pageSize = pageSize
        self.fetch = fetch
    }

    /// First page. No-op while a load is running or once loaded (use `refresh()` to reload).
    public func loadFirst() async {
        guard !phase.isLoading, !isRefreshing, items.isEmpty else { return }
        phase = .loadingFirst
        do {
            apply(try await fetch(PaginationInputEntity(page: 1, limit: pageSize)), replacing: true)
        } catch {
            let error = ResponseError.from(error)
            phase = error == .cancelled ? .idle : .failure(error)
        }
    }

    /// Call from each row's `.onAppear`; loads the next page near the end of the list.
    public func loadMoreIfNeeded(currentItem item: Item) async {
        guard hasNext, phase == .loaded, !isRefreshing,
            let index = items.firstIndex(where: { $0.id == item.id }),
            index >= items.count - prefetchDistance
        else { return }
        await loadMore()
    }

    /// The "tap to retry" row after a failed next page.
    public func retryMore() async {
        guard case .failureMore = phase else { return }
        phase = .loaded
        await loadMore()
    }

    /// Pull to refresh. Keeps the current items on screen and swaps them in one go when page 1 arrives.
    /// Throws on failure so the screen can show a snackbar (§6m); the old items stay.
    public func refresh() async throws(ResponseError) {
        guard !isRefreshing else { return }
        guard !items.isEmpty else {
            await reloadFromScratch()
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            apply(try await fetch(PaginationInputEntity(page: 1, limit: pageSize)), replacing: true)
        } catch {
            let error = ResponseError.from(error)
            if error != .cancelled { throw error }
        }
    }

    private func reloadFromScratch() async {
        if case .failure = phase { phase = .idle }
        if phase == .empty { phase = .idle }
        await loadFirst()
    }

    private func loadMore() async {
        phase = .loadingMore
        do {
            apply(try await fetch(PaginationInputEntity(page: page + 1, limit: pageSize)), replacing: false)
        } catch {
            let error = ResponseError.from(error)
            phase = error == .cancelled ? .loaded : .failureMore(error)
        }
    }

    private func apply(_ result: PaginatedEntity<Item>, replacing: Bool) {
        items = replacing ? result.items : items + result.items
        page = result.page
        hasNext = result.hasNext
        phase = items.isEmpty ? .empty : .loaded
    }
}
