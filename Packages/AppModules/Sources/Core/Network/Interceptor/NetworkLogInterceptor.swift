import Foundation

/// Logs every request and response to `AppLogger.network`. Development/staging only (`enabled: env.isDiagnosticsEnabled`).
/// Bodies are logged only in DEBUG builds and always through `LogRedactor`. Put it first in the chain.
public struct NetworkLogInterceptor: RequestInterceptor {
    private let enabled: Bool
    private static let maxBodyLength = 2_000

    public init(enabled: Bool) {
        self.enabled = enabled
    }

    public func adapt(_ request: URLRequest, for endpoint: any Endpoint) async throws -> URLRequest {
        guard enabled else { return request }
        let method = request.httpMethod ?? "?"
        AppLogger.network.info("→ \(method, privacy: .public) \(endpoint.path, privacy: .public)")
        #if DEBUG
            if let body = request.httpBody { logBody(body, direction: "→") }
        #endif
        return request
    }

    public func intercept(
        _ response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        endpoint: any Endpoint,
        attempt: Int
    ) async throws -> InterceptorOutcome {
        guard enabled else { return .proceed }
        let status = response.statusCode
        AppLogger.network.info(
            "← \(status, privacy: .public) \(endpoint.path, privacy: .public) (\(data.count, privacy: .public) bytes)")
        #if DEBUG
            logBody(data, direction: "←")
        #endif
        return .proceed
    }

    public func didFail(_ error: any Error, for request: URLRequest) async {
        guard enabled else { return }
        let path = request.url?.path() ?? "?"
        AppLogger.network.notice("✕ \(path, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }

    private func logBody(_ data: Data, direction: String) {
        guard !data.isEmpty else { return }
        let text = LogRedactor.redact(String(decoding: data.prefix(Self.maxBodyLength), as: UTF8.self))
        AppLogger.network.debug("\(direction, privacy: .public) \(text, privacy: .private)")
    }
}
