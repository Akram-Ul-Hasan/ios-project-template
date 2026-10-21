import Foundation

/// Values that differ per flavor. They come from xcconfig → Info.plist, never from Swift literals (§6o).
public struct Env: Sendable, Equatable {
    public let environment: AppEnvironment
    public let baseURL: URL
    /// SPKI SHA-256 pins (base64) for `baseURL`'s host. Empty = no pinning (development).
    public let pinnedKeyHashes: Set<String>

    public init(environment: AppEnvironment, baseURL: URL, pinnedKeyHashes: Set<String>) {
        self.environment = environment
        self.baseURL = baseURL
        self.pinnedKeyHashes = pinnedKeyHashes
    }

    /// Reads `APP_ENV` and `BASE_URL` from an Info.plist dictionary.
    public init(infoDictionary: [String: Any]) throws(EnvError) {
        guard let rawEnvironment = infoDictionary[Key.environment] as? String else {
            throw .missing(Key.environment)
        }
        guard let environment = AppEnvironment(rawValue: rawEnvironment) else {
            throw .invalid(Key.environment, rawEnvironment)
        }
        guard let rawURL = infoDictionary[Key.baseURL] as? String else { throw .missing(Key.baseURL) }
        guard let baseURL = URL(string: rawURL), baseURL.scheme == "https", baseURL.host() != nil else {
            throw .invalid(Key.baseURL, rawURL)
        }
        // Optional; space- or comma-separated.
        let pins = (infoDictionary[Key.pins] as? String ?? "")
            .split { $0 == " " || $0 == "," }
            .map(String.init)
        self.init(environment: environment, baseURL: baseURL, pinnedKeyHashes: Set(pins))
    }

    /// The running app's values. Throws only when the build configuration is broken.
    public static func fromMainBundle() throws(EnvError) -> Env {
        try Env(infoDictionary: Bundle.main.infoDictionary ?? [:])
    }

    /// Verbose network logging, debug menu, log export: development and staging only.
    public var isDiagnosticsEnabled: Bool { environment != .production }

    private enum Key {
        static let environment = "APP_ENV"
        static let baseURL = "BASE_URL"
        static let pins = "PINNED_PUBLIC_KEY_HASHES"
    }
}

public enum EnvError: Error, Equatable, Sendable {
    case missing(String)
    case invalid(String, String)
}
