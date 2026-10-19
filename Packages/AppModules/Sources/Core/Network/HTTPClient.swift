/// The only way features talk to the backend. Every error it throws is a `ResponseError`.
public protocol HTTPClient: Sendable {
    func send<Response: Decodable & Sendable>(_ endpoint: any Endpoint, as type: Response.Type) async throws -> Response
    /// For endpoints whose response body is irrelevant (204, fire-and-forget).
    func send(_ endpoint: any Endpoint) async throws
}

extension HTTPClient {
    /// `let response: LoginResponse = try await client.send(AuthEndpoint.login(request))`
    public func send<Response: Decodable & Sendable>(_ endpoint: any Endpoint) async throws -> Response {
        try await send(endpoint, as: Response.self)
    }
}
