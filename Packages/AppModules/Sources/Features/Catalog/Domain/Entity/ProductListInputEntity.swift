import SharedDomain

public struct ProductListInputEntity: Equatable, Sendable {
    /// `nil` = no search, the full catalog.
    public let query: String?
    public let pagination: PaginationInputEntity

    public init(query: String?, pagination: PaginationInputEntity) {
        self.query = query
        self.pagination = pagination
    }
}
