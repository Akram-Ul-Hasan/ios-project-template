import Foundation
import Testing

@testable import Core

@Suite("PreferencesStore")
struct PreferencesStoreTests {
    private static let flag = PreferenceKey(name: "flag", defaultValue: false, scope: .device)
    private static let lastTab = PreferenceKey<String?>(name: "last_tab", defaultValue: nil, scope: .user)
    private static let count = PreferenceKey(name: "count", defaultValue: 0, scope: .user)

    enum Kind: CaseIterable { case userDefaults, inMemory }

    private func makeStore(_ kind: Kind) -> CodablePreferencesStore {
        switch kind {
        case .userDefaults:
            // A throwaway suite per test, never .standard.
            UserDefaultsPreferencesStore(defaults: UserDefaults(suiteName: "tests.\(UUID().uuidString)")!)
        case .inMemory:
            InMemoryPreferencesStore()
        }
    }

    @Test("Missing keys return their default; set and remove round-trip", arguments: Kind.allCases)
    func roundTrip(kind: Kind) {
        let store = makeStore(kind)
        #expect(store.value(Self.flag) == false)
        store.set(true, for: Self.flag)
        #expect(store.value(Self.flag) == true)
        store.set("cart", for: Self.lastTab)
        #expect(store.value(Self.lastTab) == "cart")
        store.remove(Self.flag)
        #expect(store.value(Self.flag) == false)
    }

    @Test("removeAll(scope:) only clears that scope", arguments: Kind.allCases)
    func scopes(kind: Kind) {
        let store = makeStore(kind)
        store.set(true, for: Self.flag)
        store.set("cart", for: Self.lastTab)
        store.set(3, for: Self.count)
        store.removeAll(scope: .user)
        #expect(store.value(Self.flag) == true)
        #expect(store.value(Self.lastTab) == nil)
        #expect(store.value(Self.count) == 0)
    }

    @Test("changes emits the current value, then every change", arguments: Kind.allCases)
    func changes(kind: Kind) async {
        let store = makeStore(kind)
        var iterator = store.changes(Self.count).makeAsyncIterator()
        #expect(await iterator.next() == 0)
        store.set(1, for: Self.count)
        #expect(await iterator.next() == 1)
        store.remove(Self.count)
        #expect(await iterator.next() == 0)
    }

    @Test("App keys have safe defaults")
    func appKeys() {
        let store = InMemoryPreferencesStore()
        #expect(store.value(.onboardingSeen) == false)
        #expect(store.value(.hasLaunchedBefore) == false)
        #expect(store.value(.language) == nil)
        #expect(store.value(.themeMode) == "system")
    }
}
