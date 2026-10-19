/// A typed preference: name, default and scope. LOW-security values only (§6g): never tokens or PII.
/// App-wide keys are in `AppPreferenceKeys`; feature keys live in the feature's `Data/DataSource/Local/`.
public struct PreferenceKey<Value: Codable & Sendable>: Sendable {
    public let name: String
    public let defaultValue: Value
    public let scope: PreferenceScope

    public init(name: String, defaultValue: Value, scope: PreferenceScope) {
        self.name = name
        self.defaultValue = defaultValue
        self.scope = scope
    }
}

public enum PreferenceScope: String, Sendable {
    /// Survives logout (theme, language, onboarding seen).
    case device
    /// Belongs to the logged-in user; `SessionCleaner` wipes it on logout.
    case user
}
