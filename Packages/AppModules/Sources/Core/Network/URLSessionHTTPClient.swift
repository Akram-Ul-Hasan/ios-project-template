import Foundation

/// `HTTPClient` on URLSession. Interceptors run in array order for both requests and responses; the usual chain is
/// `[NetworkLogInterceptor, AuthTokenInterceptor, LanguageInterceptor, BackendErrorInterceptor]`
/// (log first so it sees every response, error mapping last so a 401 can still be retried after a refresh).
public final class URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let interceptors: [any RequestInterceptor]
    private let decoder = JSONDecoder.app
    private let encoder = JSONEncoder.app

    public init(baseURL: URL, session: URLSession, interceptors: [any RequestInterceptor]) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = interceptors
    }

    /// Fails fast instead of waiting for connectivity; `delegate` is where certificate pinning plugs in.
    public static func makeSession(delegate: (any URLSessionDelegate)? = nil) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NetworkConstants.requestTimeout
        configuration.timeoutIntervalForResource = NetworkConstants.resourceTimeout
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    // `@concurrent`: networking and decoding never run on the main actor, even when a view model awaits them.
    @concurrent
    public func send<Response: Decodable & Sendable>(
        _ endpoint: any Endpoint,
        as type: Response.Type
    ) async throws -> Response {
        let data = try await perform(endpoint)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            let mapped = ResponseError.from(error)
            if case .invalidResponse(let detail) = mapped {
                AppLogger.network.error(
                    "contract broken: \(endpoint.path, privacy: .public) \(detail, privacy: .public)")
            }
            throw mapped
        }
    }

    @concurrent
    public func send(_ endpoint: any Endpoint) async throws {
        _ = try await perform(endpoint)
    }

    private func perform(_ endpoint: any Endpoint) async throws -> Data {
        do {
            var attempt = 0
            while true {
                var request = try endpoint.makeRequest(baseURL: baseURL, encoder: encoder)
                for interceptor in interceptors {
                    request = try await interceptor.adapt(request, for: endpoint)
                }

                let (data, response) = try await load(request)
                guard let http = response as? HTTPURLResponse else { throw ResponseError.unknown }

                if try await shouldRetry(http, data: data, request: request, endpoint: endpoint, attempt: attempt),
                    attempt < NetworkConstants.maxRetryCount
                {
                    attempt += 1
                    continue
                }
                // Safety net when no interceptor mapped the failure.
                guard (200..<300).contains(http.statusCode) else {
                    throw ResponseError.from(
                        statusCode: http.statusCode, body: try? JSONDecoder().decode(BackendError.self, from: data))
                }
                return data
            }
        } catch {
            throw ResponseError.from(error)
        }
    }

    private func load(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            for interceptor in interceptors {
                await interceptor.didFail(error, for: request)
            }
            throw error
        }
    }

    private func shouldRetry(
        _ response: HTTPURLResponse,
        data: Data,
        request: URLRequest,
        endpoint: any Endpoint,
        attempt: Int
    ) async throws -> Bool {
        for interceptor in interceptors {
            let outcome = try await interceptor.intercept(
                response, data: data, for: request, endpoint: endpoint, attempt: attempt)
            if outcome == .retry { return true }
        }
        return false
    }
}
