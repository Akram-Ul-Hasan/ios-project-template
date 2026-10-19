import Core
import Foundation
import os

/// `KeychainStoring` backed by a dictionary, for tests and previews.
public final class InMemoryKeychain: KeychainStoring {
    private let items = OSAllocatedUnfairLock<[KeychainKey: Data]>(initialState: [:])

    public init() {}

    public func data(for key: KeychainKey) throws(KeychainError) -> Data? { items.withLock { $0[key] } }

    public func set(_ data: Data, for key: KeychainKey, protection: KeychainProtection) throws(KeychainError) {
        items.withLock { $0[key] = data }
    }

    public func remove(_ key: KeychainKey) throws(KeychainError) { items.withLock { $0[key] = nil } }
}
