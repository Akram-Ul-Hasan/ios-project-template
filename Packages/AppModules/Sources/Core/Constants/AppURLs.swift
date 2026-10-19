import Foundation

/// Static web pages. Paths only: the host comes from `Env` so each flavor opens its own site.
public enum AppURLs {
    public static let termsPath = "/legal/terms"
    public static let privacyPath = "/legal/privacy"
    public static let supportPath = "/support"

    public static func url(_ path: String, env: Env) -> URL {
        env.baseURL.appending(path: path)
    }
}
