import Foundation
import TestSupport
import Testing
import os

@testable import Core

@Suite("Session")
@MainActor
struct SessionTests {
    private final class Biometrics: BiometricAuthenticating {
        let isAvailable: Bool
        let succeeds: Bool
        init(isAvailable: Bool = true, succeeds: Bool = true) {
            self.isAvailable = isAvailable
            self.succeeds = succeeds
        }
        func authenticate(reason: String) async -> Bool { succeeds }
    }

    private struct Recorder: SessionCleanable {
        let name: String
        let log: OSAllocatedUnfairLock<[String]>
        var fails = false
        func clearSessionData() async throws {
            log.withLock { $0.append(name) }
            if fails { throw ResponseError.unknown }
        }
    }

    private func manager(_ biometrics: Biometrics, cleaner: SessionCleaner = SessionCleaner(cleanables: []))
        -> SessionManager
    {
        let manager = SessionManager(
            cleaner: cleaner, events: SessionEvents(), biometrics: biometrics, lockTimeout: .seconds(60))
        manager.isBiometricLockEnabled = true
        return manager
    }

    @Test("Locks only after the timeout in the background")
    func lockAfterTimeout() {
        let manager = manager(Biometrics())
        let start = ContinuousClock.now
        manager.didEnterBackground(at: start)
        manager.willEnterForeground(at: start + .seconds(30))
        #expect(!manager.isLocked)
        manager.didEnterBackground(at: start)
        manager.willEnterForeground(at: start + .seconds(61))
        #expect(manager.isLocked)
    }

    @Test("Never locks without biometrics or when disabled")
    func noLock() {
        let unavailable = manager(Biometrics(isAvailable: false))
        let start = ContinuousClock.now
        unavailable.didEnterBackground(at: start)
        unavailable.willEnterForeground(at: start + .seconds(600))
        #expect(!unavailable.isLocked)

        let disabled = manager(Biometrics())
        disabled.isBiometricLockEnabled = false
        disabled.didEnterBackground(at: start)
        disabled.willEnterForeground(at: start + .seconds(600))
        #expect(!disabled.isLocked)
    }

    @Test("Unlock succeeds only when authentication does")
    func unlock() async {
        let failing = manager(Biometrics(succeeds: false))
        let start = ContinuousClock.now
        failing.didEnterBackground(at: start)
        failing.willEnterForeground(at: start + .seconds(61))
        #expect(await failing.unlock() == false)
        #expect(failing.isLocked)

        let passing = manager(Biometrics())
        passing.didEnterBackground(at: start)
        passing.willEnterForeground(at: start + .seconds(61))
        #expect(await passing.unlock())
        #expect(!passing.isLocked)
    }

    @Test("Logout wipes every store even if one fails, then publishes loggedOut")
    func logout() async {
        let log = OSAllocatedUnfairLock<[String]>(initialState: [])
        let cleaner = SessionCleaner(cleanables: [
            Recorder(name: "a", log: log), Recorder(name: "b", log: log, fails: true), Recorder(name: "c", log: log),
        ])
        let events = SessionEvents()
        let manager = SessionManager(
            cleaner: cleaner, events: events, biometrics: Biometrics(), lockTimeout: .seconds(1))
        var iterator = events.stream().makeAsyncIterator()
        await manager.logout()
        #expect(log.withLock { $0 } == ["a", "b", "c"])
        #expect(await iterator.next() == .loggedOut)
    }

    @Test("Real stores clear their user data")
    func realStores() async throws {
        let tokens = SecureTokenStore(keychain: InMemoryKeychain())
        try tokens.save(AuthTokens(accessToken: "a", refreshToken: "r"))
        let preferences = InMemoryPreferencesStore()
        preferences.set("cart", for: .lastSelectedTab)
        preferences.set(true, for: .onboardingSeen)

        await SessionCleaner(cleanables: [tokens, preferences]).clean()
        #expect(tokens.tokens() == nil)
        #expect(preferences.value(.lastSelectedTab) == nil)
        #expect(preferences.value(.onboardingSeen))
    }
}
