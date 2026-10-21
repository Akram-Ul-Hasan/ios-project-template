import Foundation
import SharedDomain

/// Backs the mock data sources used by the development flavor (§5): loads JSON fixtures with the same decoder
/// and DTOs as the remote path, and pages through them.
///
/// Fixtures live in `App/Resources/Mock/<feature>/` and are named `<feature>-<name>.mock.json`: Xcode copies them
/// flat into the bundle (so names must be unique) and every non-development build excludes `*.mock.json`.
public struct MockDataHelper: Sendable {
    private let bundle: Bundle
    private let latency: Duration

    public init(bundle: Bundle = .main, latency: Duration = NetworkConstants.mockLatency) {
        self.bundle = bundle
        self.latency = latency
    }

    /// `try await mock.load("auth-login")` decodes `auth-login.mock.json`.
    public func load<Response: Decodable & Sendable>(
        _ fixture: String,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        try await Task.sleep(for: latency)
        guard let url = url(for: fixture) else {
            AppLogger.network.fault("missing mock fixture \(fixture, privacy: .public)")
            throw ResponseError.invalidResponse(detail: "missing fixture \(fixture)")
        }
        do {
            return try JSONDecoder.app.decode(Response.self, from: Data(contentsOf: url))
        } catch {
            throw ResponseError.from(error)
        }
    }

    /// Fake server-side paging over a full fixture list. `page` starts at 1.
    public func paginate<Item: Equatable & Sendable>(
        _ items: [Item],
        input: PaginationInputEntity
    ) -> PaginatedEntity<Item> {
        let start = max(0, (input.page - 1) * input.limit)
        let end = min(items.count, start + max(0, input.limit))
        let page = start < end ? Array(items[start..<end]) : []
        return PaginatedEntity(items: page, page: input.page, hasNext: end < items.count)
    }

    func url(for fixture: String) -> URL? {
        bundle.url(forResource: "\(fixture).mock", withExtension: "json")
    }
}
