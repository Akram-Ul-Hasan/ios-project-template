import Foundation
import TestSupport
import Testing
import os

@testable import Core

@Suite("URLSessionHTTPClient")
struct URLSessionHTTPClientTests {
    private struct Profile: Decodable, Equatable {
        let fullName: String
    }

    private struct GetProfile: Endpoint {
        var path: String { "/v1/me" }
        var method: HTTPMethod { .get }
    }

    private func client(
        _ host: String,
        interceptors: [any RequestInterceptor] = [],
        handler: @escaping StubURLProtocol.Handler
    ) -> URLSessionHTTPClient {
        URLSessionHTTPClient(
            baseURL: URL(string: "https://\(host)")!,
            session: StubURLProtocol.session(host: host, handler: handler),
            interceptors: interceptors)
    }

    @Test("Decodes a 2xx body with the app decoder")
    func success() async throws {
        let client = client("ok.test") { _ in (200, Data(#"{"full_name":"Rahim"}"#.utf8)) }
        let profile: Profile = try await client.send(GetProfile())
        #expect(profile == Profile(fullName: "Rahim"))
    }

    @Test("A 422 keeps the API's field-error keys")
    func validation() async {
        let body = #"{"message":"Invalid","errors":{"phone_number":["Taken"]}}"#
        let client = client("422.test") { _ in (422, Data(body.utf8)) }
        await #expect(throws: ResponseError.validation(message: "Invalid", fieldErrors: ["phone_number": ["Taken"]])) {
            try await client.send(GetProfile())
        }
    }

    @Test("A broken contract becomes invalidResponse")
    func contract() async {
        let client = client("contract.test") { _ in (200, Data(#"{"name":"x"}"#.utf8)) }
        await #expect(throws: ResponseError.invalidResponse(detail: "missing key fullName")) {
            let _: Profile = try await client.send(GetProfile())
        }
    }

    @Test("Transport errors are mapped")
    func offline() async {
        let client = client("offline.test") { _ in throw URLError(.notConnectedToInternet) }
        await #expect(throws: ResponseError.network) { try await client.send(GetProfile()) }
    }

    @Test("Interceptors adapt in order, and a retry resends once")
    func chain() async throws {
        let calls = OSAllocatedUnfairLock(initialState: 0)
        let client = client("chain.test", interceptors: [Header("A", "1"), Header("B", "2"), RetryOn401()]) { request in
            #expect(request.value(forHTTPHeaderField: "A") == "1")
            #expect(request.value(forHTTPHeaderField: "B") == "2")
            let call = calls.withLock {
                $0 += 1
                return $0
            }
            return call == 1 ? (401, Data()) : (200, Data(#"{"full_name":"R"}"#.utf8))
        }
        let _: Profile = try await client.send(GetProfile())
        #expect(calls.withLock { $0 } == 2)
    }

    @Test("Retries stop after the limit")
    func retryLimit() async {
        let client = client("limit.test", interceptors: [RetryOn401()]) { _ in (401, Data()) }
        await #expect(throws: ResponseError.unauthorized) { try await client.send(GetProfile()) }
    }

    private struct Header: RequestInterceptor {
        let name: String
        let value: String
        init(_ name: String, _ value: String) {
            self.name = name
            self.value = value
        }
        func adapt(_ request: URLRequest, for endpoint: any Endpoint) async throws -> URLRequest {
            var request = request
            request.setValue(value, forHTTPHeaderField: name)
            return request
        }
    }

    private struct RetryOn401: RequestInterceptor {
        func intercept(
            _ response: HTTPURLResponse, data: Data, for request: URLRequest, endpoint: any Endpoint, attempt: Int
        ) async throws -> InterceptorOutcome {
            response.statusCode == 401 ? .retry : .proceed
        }
    }
}
