/// Low-security key-value storage (rule 20). `@AppStorage` and `UserDefaults.standard` are banned everywhere else.
public protocol PreferencesStore: Sendable {
    func value<Value>(_ key: PreferenceKey<Value>) -> Value
    func set<Value>(_ value: Value, for key: PreferenceKey<Value>)
    func remove<Value>(_ key: PreferenceKey<Value>)
    /// The current value, then every change. Ends when the consuming task is cancelled.
    func changes<Value>(_ key: PreferenceKey<Value>) -> AsyncStream<Value>
    /// Removes every key of `scope` that was ever written (logout uses `.user`).
    func removeAll(scope: PreferenceScope)
}
