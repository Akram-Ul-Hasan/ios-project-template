import Foundation

/// Values that differ per flavor. They come from xcconfig → Info.plist, never from Swift literals (§6o).
public struct Env: Sendable, Equatable {
    public let environment: AppEnvironment
    public let baseURL: URL

    public init(environment: AppEnvironment, baseURL: URL) {
        self.environment = environment
        self.baseURL = baseURL
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
        self.init(environment: environment, baseURL: baseURL)
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
    }
}

public enum EnvError: Error, Equatable, Sendable {
    case missing(String)
    case invalid(String, String)
}
