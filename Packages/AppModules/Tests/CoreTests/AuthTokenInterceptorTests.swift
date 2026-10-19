import Foundation
import TestSupport
import Testing
import os

@testable import Core

@Suite("AuthTokenInterceptor")
struct AuthTokenInterceptorTests {
    private struct Me: Endpoint {
        var path: String { "/v1/me" }
        var method: HTTPMethod { .get }
    }

    private struct Login: Endpoint {
        var path: String { "/v1/login" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { false }
    }

    private let store = SecureTokenStore(keychain: InMemoryKeychain())

    private func client(_ host: String, refresher: TokenRefresher, handler: @escaping StubURLProtocol.Handler)
        -> URLSessionHTTPClient
    {
        URLSessionHTTPClient(
            baseURL: URL(string: "https://\(host)")!,
            session: StubURLProtocol.session(host: host, handler: handler),
            interceptors: [AuthTokenInterceptor(store: store, refresher: refresher), BackendErrorInterceptor()])
    }

    @Test("Adds the bearer token only to endpoints that require auth")
    func bearer() async throws {
        try store.save(AuthTokens(accessToken: "a1", refreshToken: "r1"))
        let refresher = TokenRefresher(store: store, events: SessionEvents()) { _ in throw ResponseError.unknown }
        let headers = OSAllocatedUnfairLock<[String: String?]>(initialState: [:])
        let client = client("bearer.test", refresher: refresher) { request in
            headers.withLock { $0[request.url?.path() ?? ""] = request.value(forHTTPHeaderField: "Authorization") }
            return (204, Data())
        }
        try await client.send(Me())
        try await client.send(Login())
        #expect(headers.withLock { $0["/v1/me"] } == "Bearer a1")
        #expect(headers.withLock { $0["/v1/login"] } == .some(nil))
    }

    @Test("A 401 refreshes and retries with the new token")
    func refreshAndRetry() async throws {
        try store.save(AuthTokens(accessToken: "expired", refreshToken: "r1"))
        let refresher = TokenRefresher(store: store, events: SessionEvents()) { _ in
            AuthTokens(accessToken: "fresh", refreshToken: "r2")
        }
        let client = client("retry.test", refresher: refresher) { request in
            request.value(forHTTPHeaderField: "Authorization") == "Bearer fresh" ? (204, Data()) : (401, Data())
        }
        try await client.send(Me())
        #expect(store.tokens()?.accessToken == "fresh")
    }

    @Test("A failed refresh surfaces as unauthorized")
    func refreshFails() async throws {
        try store.save(AuthTokens(accessToken: "expired", refreshToken: "r1"))
        let refresher = TokenRefresher(store: store, events: SessionEvents()) { _ in throw ResponseError.forbidden }
        let client = client("fail.test", refresher: refresher) { _ in (401, Data()) }
        await #expect(throws: ResponseError.unauthorized) { try await client.send(Me()) }
    }
}
