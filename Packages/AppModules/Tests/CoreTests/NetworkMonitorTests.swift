import Testing

@testable import Core

@Suite("NetworkMonitor")
@MainActor
struct NetworkMonitorTests {
    @Test("Applies path snapshots")
    func apply() {
        let monitor = NetworkMonitor()
        monitor.apply(.init(isOnline: false, connectionType: .none, isExpensive: false, isConstrained: false))
        #expect(!monitor.isOnline && monitor.connectionType == .none)
        monitor.apply(.init(isOnline: true, connectionType: .cellular, isExpensive: true, isConstrained: true))
        #expect(monitor.isOnline && monitor.connectionType == .cellular && monitor.isExpensive && monitor.isConstrained)
    }

    @Test("Preview monitors are fixed in one state")
    func preview() {
        #expect(!NetworkMonitor.preview(isOnline: false).isOnline)
        #expect(NetworkMonitor.preview(isOnline: true).connectionType == .wifi)
    }

    @Test("Starting twice is harmless")
    func startTwice() {
        let monitor = NetworkMonitor()
        monitor.start()
        monitor.start()
    }
}
