import Core
import SharedDomain

/// Development data from `App/Resources/Mock/__feature_lower__/`.
public struct __Feature__MockDataSource: __Feature__DataSource {
    private let mock: MockDataHelper

    public init(mock: MockDataHelper) {
        self.mock = mock
    }

    public func items(page: Int, limit: Int) async throws -> __Feature__PageResponse {
        let all: [__Feature__ItemResponse] = try await mock.load("__feature_lower__-items")
        let slice = mock.paginate(all, input: PaginationInputEntity(page: page, limit: limit))
        return __Feature__PageResponse(items: slice.items, page: slice.page, hasNext: slice.hasNext)
    }
}
