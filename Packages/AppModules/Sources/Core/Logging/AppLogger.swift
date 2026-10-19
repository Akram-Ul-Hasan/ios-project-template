import Foundation
import os

/// One `Logger` per category (rule 31). Filter in Console.app by subsystem = bundle id, then category.
/// Dynamic values are `.private` by default; mark `.public` only for non-PII (paths, status codes, screen names).
/// Stateless value types, so this is the one allowed static namespace besides `L10n` (rule 24).
public enum AppLogger {
    public static let network = Logger(subsystem: subsystem, category: "network")
    public static let auth = Logger(subsystem: subsystem, category: "auth")
    public static let navigation = Logger(subsystem: subsystem, category: "navigation")
    public static let persistence = Logger(subsystem: subsystem, category: "persistence")
    public static let ui = Logger(subsystem: subsystem, category: "ui")
    public static let security = Logger(subsystem: subsystem, category: "security")
    public static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")

    public static let subsystem = Bundle.main.bundleIdentifier ?? "com.technonext.projecttemplate"
}
