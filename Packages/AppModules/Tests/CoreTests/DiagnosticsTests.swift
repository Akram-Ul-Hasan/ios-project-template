import Foundation
import MetricKit
import Testing

@testable import Core

@Suite("Diagnostics")
struct DiagnosticsTests {
    @Test("The MetricKit subscriber can start and stop")
    func metrics() {
        let collector = MetricsCollector(upload: nil)
        collector.start()
        collector.didReceive([MXDiagnosticPayload]())
        collector.stop()
    }
}
