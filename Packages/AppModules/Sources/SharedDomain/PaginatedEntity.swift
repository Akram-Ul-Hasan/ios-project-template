/// One page of results, as returned by any paginated repository.
public struct PaginatedEntity<Item: Equatable & Sendable>: Equatable, Sendable {
    public let items: [Item]
    public let page: Int
    public let hasNext: Bool

    public init(items: [Item], page: Int, hasNext: Bool) {
        self.items = items
        self.page = page
        self.hasNext = hasNext
    }
}
