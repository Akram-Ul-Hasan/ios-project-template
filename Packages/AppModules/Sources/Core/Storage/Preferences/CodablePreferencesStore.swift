import Foundation
import os

/// Shared engine of the two stores: JSON-encodes values into a raw `Data` storage and notifies observers.
public class CodablePreferencesStore: PreferencesStore, @unchecked Sendable {
    // @unchecked: `storage` is thread-safe by contract and every other mutable state is behind `observers`' lock.
    private let storage: any RawPreferenceStorage
    private let observers = OSAllocatedUnfairLock<[String: [UUID: @Sendable () -> Void]]>(initialState: [:])
    private static let scopeIndexPrefix = "__keys_"

    init(storage: any RawPreferenceStorage) {
        self.storage = storage
    }

    public func value<Value>(_ key: PreferenceKey<Value>) -> Value {
        guard let data = storage.data(forKey: key.name) else { return key.defaultValue }
        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            AppLogger.persistence.error("preference \(key.name, privacy: .public) unreadable, using default")
            return key.defaultValue
        }
    }

    public func set<Value>(_ value: Value, for key: PreferenceKey<Value>) {
        do {
            storage.set(try JSONEncoder().encode(value), forKey: key.name)
            index(key.name, scope: key.scope)
            notify(key.name)
        } catch {
            AppLogger.persistence.error("preference \(key.name, privacy: .public) not encodable")
        }
    }

    public func remove<Value>(_ key: PreferenceKey<Value>) {
        storage.removeValue(forKey: key.name)
        notify(key.name)
    }

    public func changes<Value>(_ key: PreferenceKey<Value>) -> AsyncStream<Value> {
        AsyncStream { continuation in
            let id = UUID()
            observers.withLock {
                $0[key.name, default: [:]][id] = { [weak self] in
                    guard let self else { return }
                    continuation.yield(self.value(key))
                }
            }
            continuation.onTermination = { [weak self] _ in
                self?.observers.withLock { $0[key.name]?[id] = nil }
            }
            continuation.yield(value(key))
        }
    }

    public func removeAll(scope: PreferenceScope) {
        let names = indexedNames(scope)
        for name in names {
            storage.removeValue(forKey: name)
        }
        storage.removeValue(forKey: Self.scopeIndexPrefix + scope.rawValue)
        for name in names {
            notify(name)
        }
    }

    private func notify(_ name: String) {
        let callbacks = observers.withLock { Array(($0[name] ?? [:]).values) }
        for callback in callbacks {
            callback()
        }
    }

    private func indexedNames(_ scope: PreferenceScope) -> [String] {
        guard let data = storage.data(forKey: Self.scopeIndexPrefix + scope.rawValue) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func index(_ name: String, scope: PreferenceScope) {
        var names = indexedNames(scope)
        guard !names.contains(name) else { return }
        names.append(name)
        if let data = try? JSONEncoder().encode(names) {
            storage.set(data, forKey: Self.scopeIndexPrefix + scope.rawValue)
        }
    }
}

/// Byte storage behind `CodablePreferencesStore`. Implementations must be thread-safe.
protocol RawPreferenceStorage: Sendable {
    func data(forKey key: String) -> Data?
    func set(_ data: Data, forKey key: String)
    func removeValue(forKey key: String)
}
