import Core

public struct __Feature__RemoteDataSource: __Feature__DataSource {
    private let client: any HTTPClient

    public init(client: any HTTPClient) {
        self.client = client
    }

    public func items(page: Int, limit: Int) async throws -> __Feature__PageResponse {
        try await client.send(__Feature__Endpoint.items(page: page, limit: limit))
    }
}
