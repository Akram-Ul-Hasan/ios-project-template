public protocol __Feature__DataSource: Sendable {
    func items(page: Int, limit: Int) async throws -> __Feature__PageResponse
}
