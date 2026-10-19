import Foundation
import MetricKit
import Testing

@testable import Core

@Suite("Diagnostics")
struct DiagnosticsTests {
    @Test("Exported logs contain this run's messages with category and level")
    func export() async throws {
        let start = Date.now.addingTimeInterval(-1)
        let marker = UUID().uuidString
        AppLogger.lifecycle.notice("export-test \(marker, privacy: .public)")

        let url = try await LogExporter().export(since: start)
        defer { try? FileManager.default.removeItem(at: url) }
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("export-test \(marker)"))
        #expect(text.contains("[lifecycle] NOTICE"))
    }

    @Test("The MetricKit subscriber can start and stop")
    func metrics() {
        let collector = MetricsCollector(upload: nil)
        collector.start()
        collector.didReceive([MXDiagnosticPayload]())
        collector.stop()
    }
}
