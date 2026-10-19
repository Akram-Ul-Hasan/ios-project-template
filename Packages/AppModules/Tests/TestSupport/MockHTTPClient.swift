import Core
import Foundation
import os

/// `HTTPClient` that answers from stubs keyed by path and records every request, for data-source tests.
public final class MockHTTPClient: HTTPClient {
    private struct State {
        var stubs: [String: Result<Data, ResponseError>] = [:]
        var sent: [String] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    public init() {}

    public func stub(_ path: String, json: String) {
        state.withLock { $0.stubs[path] = .success(Data(json.utf8)) }
    }

    public func stub(_ path: String, error: ResponseError) {
        state.withLock { $0.stubs[path] = .failure(error) }
    }

    /// Paths in the order they were requested.
    public var sentPaths: [String] { state.withLock { $0.sent } }

    public func send<Response: Decodable & Sendable>(_ endpoint: any Endpoint, as type: Response.Type) async throws
        -> Response
    {
        let data = try record(endpoint).get()
        do {
            return try JSONDecoder.app.decode(Response.self, from: data)
        } catch {
            throw ResponseError.from(error)
        }
    }

    public func send(_ endpoint: any Endpoint) async throws {
        _ = try record(endpoint).get()
    }

    private func record(_ endpoint: any Endpoint) -> Result<Data, ResponseError> {
        state.withLock { state in
            state.sent.append(endpoint.path)
            return state.stubs[endpoint.path] ?? .failure(.notFound)
        }
    }
}
