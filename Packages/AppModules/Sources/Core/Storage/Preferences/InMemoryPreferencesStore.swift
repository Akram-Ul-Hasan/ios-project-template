import Foundation
import os

/// For tests and SwiftUI previews: same behaviour as the real store, nothing persisted.
public final class InMemoryPreferencesStore: CodablePreferencesStore, @unchecked Sendable {
    public init() {
        super.init(storage: InMemoryStorage())
    }
}

private struct InMemoryStorage: RawPreferenceStorage {
    let values = OSAllocatedUnfairLock<[String: Data]>(initialState: [:])

    func data(forKey key: String) -> Data? { values.withLock { $0[key] } }
    func set(_ data: Data, forKey key: String) { values.withLock { $0[key] = data } }
    func removeValue(forKey key: String) { values.withLock { $0[key] = nil } }
}
