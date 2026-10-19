import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// One API operation. Each feature owns an enum of these (`AuthEndpoint.login(LoginRequest)`); paths never go global.
public protocol Endpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var query: [URLQueryItem] { get }
    /// Encoded as JSON with `JSONEncoder.app` (snake_case keys).
    var body: (any Encodable & Sendable)? { get }
    var headers: [String: String] { get }
    /// Secure by default: `AuthTokenInterceptor` adds the bearer token unless an endpoint opts out.
    var requiresAuth: Bool { get }
}

extension Endpoint {
    public var query: [URLQueryItem] { [] }
    public var body: (any Encodable & Sendable)? { nil }
    public var headers: [String: String] { [:] }
    public var requiresAuth: Bool { true }

    public func makeRequest(baseURL: URL, encoder: JSONEncoder) throws -> URLRequest {
        var url = baseURL.appending(path: path)
        if !query.isEmpty { url.append(queryItems: query) }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
