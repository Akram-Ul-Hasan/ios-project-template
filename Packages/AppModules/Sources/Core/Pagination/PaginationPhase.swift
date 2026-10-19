/// Where a paged list is. A failed first page and a failed next page are different on screen:
/// full-screen error vs a "tap to retry" row under the items.
public enum PaginationPhase: Equatable, Sendable {
    case idle
    case loadingFirst
    case loadingMore
    case loaded
    case empty
    case failure(ResponseError)
    case failureMore(ResponseError)

    var isLoading: Bool { self == .loadingFirst || self == .loadingMore }
}
