import Foundation

/// The production store. Pass an App Group suite when extensions (widgets, notification service) need the values.
public final class UserDefaultsPreferencesStore: CodablePreferencesStore, @unchecked Sendable {
    public init(defaults: UserDefaults = .standard) {
        super.init(storage: UserDefaultsStorage(defaults: defaults))
    }
}

private struct UserDefaultsStorage: RawPreferenceStorage, @unchecked Sendable {
    // @unchecked: UserDefaults is documented as thread-safe.
    let defaults: UserDefaults

    func data(forKey key: String) -> Data? { defaults.data(forKey: key) }
    func set(_ data: Data, forKey key: String) { defaults.set(data, forKey: key) }
    func removeValue(forKey key: String) { defaults.removeObject(forKey: key) }
}
