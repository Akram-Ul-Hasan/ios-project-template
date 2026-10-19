import Foundation

/// Turns any non-2xx response into a `ResponseError` using the backend error body. Put it last in the chain.
public struct BackendErrorInterceptor: RequestInterceptor {
    public init() {}

    public func intercept(
        _ response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        endpoint: any Endpoint,
        attempt: Int
    ) async throws -> InterceptorOutcome {
        let status = response.statusCode
        guard !(200..<300).contains(status) else { return .proceed }
        // Plain decoder: keys like "phone_number" in `errors` must keep the API spelling.
        let body = try? JSONDecoder().decode(BackendError.self, from: data)
        let error = ResponseError.from(statusCode: status, body: body)
        if status >= 500 {
            AppLogger.network.error("\(status, privacy: .public) on \(endpoint.path, privacy: .public)")
        }
        throw error
    }
}
