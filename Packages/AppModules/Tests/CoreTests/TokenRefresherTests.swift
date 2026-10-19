import Foundation
import TestSupport
import Testing
import os

@testable import Core

@Suite("TokenRefresher")
struct TokenRefresherTests {
    private let store = SecureTokenStore(keychain: InMemoryKeychain())
    private let events = SessionEvents()

    @Test("Ten concurrent 401s cause exactly one refresh")
    func singleFlight() async throws {
        try store.save(AuthTokens(accessToken: "old", refreshToken: "r0"))
        let calls = OSAllocatedUnfairLock(initialState: 0)
        let refresher = TokenRefresher(store: store, events: events) { refreshToken in
            #expect(refreshToken == "r0")
            calls.withLock { $0 += 1 }
            try await Task.sleep(for: .milliseconds(50))
            return AuthTokens(accessToken: "new", refreshToken: "r1")
        }

        let results = try await withThrowingTaskGroup(of: AuthTokens.self) { group in
            for _ in 0..<10 { group.addTask { try await refresher.refresh() } }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(calls.withLock { $0 } == 1)
        #expect(results.allSatisfy { $0.accessToken == "new" })
        #expect(store.tokens()?.refreshToken == "r1")
    }

    @Test("A rejected refresh token clears the session and publishes sessionExpired")
    func rejected() async throws {
        try store.save(AuthTokens(accessToken: "old", refreshToken: "r0"))
        let refresher = TokenRefresher(store: store, events: events) { _ in throw ResponseError.unauthorized }
        var iterator = events.stream().makeAsyncIterator()

        await #expect(throws: ResponseError.unauthorized) { try await refresher.refresh() }
        #expect(store.tokens() == nil)
        #expect(await iterator.next() == .sessionExpired)
    }

    @Test("Being offline during refresh keeps the session")
    func offline() async throws {
        try store.save(AuthTokens(accessToken: "old", refreshToken: "r0"))
        let refresher = TokenRefresher(store: store, events: events) { _ in throw URLError(.notConnectedToInternet) }
        await #expect(throws: ResponseError.network) { try await refresher.refresh() }
        #expect(store.tokens() != nil)
    }
}
