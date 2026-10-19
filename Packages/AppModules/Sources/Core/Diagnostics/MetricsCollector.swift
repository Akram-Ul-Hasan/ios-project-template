import Foundation
import MetricKit

/// Real-user crash, hang and resource-exception reports without a third-party SDK (§6n).
/// MetricKit delivers them on the next launch; each is logged as a fault and can be POSTed to our own backend.
public final class MetricsCollector: NSObject, MXMetricManagerSubscriber, Sendable {
    public typealias Upload = @Sendable (_ payloadJSON: Data) async -> Void

    private let upload: Upload?

    /// `upload`: sends the raw MetricKit JSON to the backend; `nil` only logs.
    public init(upload: Upload?) {
        self.upload = upload
    }

    public func start() {
        MXMetricManager.shared.add(self)
    }

    public func stop() {
        MXMetricManager.shared.remove(self)
    }

    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let crashes = payload.crashDiagnostics?.count ?? 0
            let hangs = payload.hangDiagnostics?.count ?? 0
            let cpu = payload.cpuExceptionDiagnostics?.count ?? 0
            let disk = payload.diskWriteExceptionDiagnostics?.count ?? 0
            AppLogger.lifecycle.fault(
                "MetricKit: \(crashes, privacy: .public) crashes, \(hangs, privacy: .public) hangs, \(cpu, privacy: .public) CPU and \(disk, privacy: .public) disk exceptions"
            )
            send(payload.jsonRepresentation())
        }
    }

    #if os(iOS)
        public func didReceive(_ payloads: [MXMetricPayload]) {
            AppLogger.lifecycle.info("MetricKit: \(payloads.count, privacy: .public) daily metric payloads")
            for payload in payloads {
                send(payload.jsonRepresentation())
            }
        }
    #endif

    private func send(_ json: Data) {
        guard let upload else { return }
        Task { await upload(json) }
    }
}
