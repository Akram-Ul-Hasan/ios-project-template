import Foundation
import OSLog

/// "Export logs" in the development/staging debug menu (§6n): this run's entries for our subsystem,
/// written to a text file QA can attach to a bug report. Private values stay redacted as `<private>`.
public struct LogExporter: Sendable {
    public init() {}

    @concurrent
    public func export(since date: Date) async throws -> URL {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let entries = try store.getEntries(
            at: store.position(date: date), matching: NSPredicate(format: "subsystem == %@", AppLogger.subsystem))
        let lines = entries.compactMap { entry -> String? in
            guard let log = entry as? OSLogEntryLog else { return nil }
            let time = log.date.formatted(.iso8601.time(includingFractionalSeconds: true))
            return "\(time) [\(log.category)] \(Self.label(log.level)) \(log.composedMessage)"
        }
        let stamp = Date.now.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false))
            .replacing(":", with: "-")
        let url = FileManager.default.temporaryDirectory.appending(path: "logs-\(stamp).log")
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func label(_ level: OSLogEntryLog.Level) -> String {
        switch level {
        case .debug: "DEBUG"
        case .info: "INFO"
        case .notice: "NOTICE"
        case .error: "ERROR"
        case .fault: "FAULT"
        default: "-"
        }
    }
}
