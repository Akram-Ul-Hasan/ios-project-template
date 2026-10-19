/// Which page to load. `page` starts at 1.
public struct PaginationInputEntity: Equatable, Sendable {
    public let page: Int
    public let limit: Int

    public init(page: Int, limit: Int) {
        self.page = page
        self.limit = limit
    }
}
