import Foundation

/// Adds `Authorization: Bearer <token>` to endpoints that require auth, and on a 401 refreshes once and retries.
public struct AuthTokenInterceptor: RequestInterceptor {
    private let store: any TokenStore
    private let refresher: TokenRefresher

    public init(store: any TokenStore, refresher: TokenRefresher) {
        self.store = store
        self.refresher = refresher
    }

    public func adapt(_ request: URLRequest, for endpoint: any Endpoint) async throws -> URLRequest {
        guard endpoint.requiresAuth, let token = store.tokens()?.accessToken else { return request }
        var request = request
        request.setValue(Self.bearer(token), forHTTPHeaderField: "Authorization")
        return request
    }

    public func intercept(
        _ response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        endpoint: any Endpoint,
        attempt: Int
    ) async throws -> InterceptorOutcome {
        guard response.statusCode == 401, endpoint.requiresAuth, attempt == 0 else { return .proceed }
        // Another request already refreshed while this one was in flight: just resend with the new token.
        if let current = store.tokens()?.accessToken,
            request.value(forHTTPHeaderField: "Authorization") != Self.bearer(current)
        {
            return .retry
        }
        _ = try await refresher.refresh()
        return .retry
    }

    private static func bearer(_ token: String) -> String { "Bearer \(token)" }
}
