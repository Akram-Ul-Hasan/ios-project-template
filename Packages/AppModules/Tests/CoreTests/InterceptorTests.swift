import Foundation
import TestSupport
import Testing

@testable import Core

@Suite("Interceptors")
struct InterceptorTests {
    private struct Checkout: Endpoint {
        var path: String { "/v1/checkout" }
        var method: HTTPMethod { .post }
    }

    @Test("BackendErrorInterceptor maps a business error body")
    func businessError() async {
        let client = URLSessionHTTPClient(
            baseURL: URL(string: "https://business.test")!,
            session: StubURLProtocol.session(host: "business.test") { _ in
                (409, Data(#"{"code":"OUT_OF_STOCK","message":"Sold out"}"#.utf8))
            },
            interceptors: [NetworkLogInterceptor(enabled: true), BackendErrorInterceptor()])
        await #expect(throws: ResponseError.business(code: .outOfStock, message: "Sold out")) {
            try await client.send(Checkout())
        }
    }

    @Test("BackendErrorInterceptor lets 2xx through")
    func success() async throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://x.test")!, statusCode: 204, httpVersion: nil, headerFields: nil)!
        let outcome = try await BackendErrorInterceptor().intercept(
            response, data: Data(), for: URLRequest(url: URL(string: "https://x.test")!), endpoint: Checkout(),
            attempt: 0)
        #expect(outcome == .proceed)
    }
}
