import Foundation

public enum InterceptorOutcome: Sendable, Equatable {
    case proceed
    /// Send the request again (adapted afresh), e.g. after refreshing an expired token.
    case retry
}

/// One link in the client's chain (Dio interceptor equivalent). All methods have no-op defaults.
public protocol RequestInterceptor: Sendable {
    /// Runs before sending, in chain order.
    func adapt(_ request: URLRequest, for endpoint: any Endpoint) async throws -> URLRequest
    /// Runs on every HTTP response, in chain order. Throw to fail the request, return `.retry` to resend it.
    func intercept(
        _ response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        endpoint: any Endpoint,
        attempt: Int
    ) async throws -> InterceptorOutcome
    /// Transport failure (offline, timeout) — there is no response.
    func didFail(_ error: any Error, for request: URLRequest) async
}

extension RequestInterceptor {
    public func adapt(_ request: URLRequest, for endpoint: any Endpoint) async throws -> URLRequest { request }

    public func intercept(
        _ response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        endpoint: any Endpoint,
        attempt: Int
    ) async throws -> InterceptorOutcome { .proceed }

    public func didFail(_ error: any Error, for request: URLRequest) async {}
}
