import Foundation
import Network
import Observation

/// Connectivity for the UI (§6m): drives the global `OfflineBanner`, the auto-retry in `ViewStateContainer`
/// and the `isOnline` guard before submit actions. "Satisfied" isn't proof of real internet (captive portals),
/// so request errors (`ResponseError.network`) remain the second signal.
@MainActor
@Observable
public final class NetworkMonitor {
    public enum ConnectionType: Sendable, Equatable {
        case wifi
        case cellular
        case wired
        case other
        case none
    }

    public private(set) var isOnline = true
    public private(set) var connectionType: ConnectionType = .other
    /// Cellular or a personal hotspot: avoid prefetching large media.
    public private(set) var isExpensive = false
    /// Low Data Mode is on.
    public private(set) var isConstrained = false

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private var isStarted = false

    public init() {}

    /// For previews: a monitor stuck in one state, never started.
    public static func preview(isOnline: Bool) -> NetworkMonitor {
        let monitor = NetworkMonitor()
        monitor.apply(
            Snapshot(
                isOnline: isOnline, connectionType: isOnline ? .wifi : .none, isExpensive: false, isConstrained: false))
        return monitor
    }

    /// Created once in `AppContainer` and started at launch.
    public func start() {
        guard !isStarted else { return }
        isStarted = true
        monitor.pathUpdateHandler = { [weak self] path in
            let snapshot = Snapshot(path)
            Task { @MainActor in self?.apply(snapshot) }
        }
        monitor.start(queue: DispatchQueue(label: "com.technonext.network-monitor", qos: .utility))
    }

    deinit {
        monitor.cancel()
    }

    func apply(_ snapshot: Snapshot) {
        if snapshot.isOnline != isOnline {
            AppLogger.network.notice("connectivity: \(snapshot.isOnline ? "online" : "offline", privacy: .public)")
        }
        isOnline = snapshot.isOnline
        connectionType = snapshot.connectionType
        isExpensive = snapshot.isExpensive
        isConstrained = snapshot.isConstrained
    }

    struct Snapshot: Sendable, Equatable {
        let isOnline: Bool
        let connectionType: ConnectionType
        let isExpensive: Bool
        let isConstrained: Bool
    }
}

extension NetworkMonitor.Snapshot {
    init(_ path: NWPath) {
        let type: NetworkMonitor.ConnectionType =
            if path.status != .satisfied { .none } else if path.usesInterfaceType(.wifi) {
                .wifi
            } else if path.usesInterfaceType(.cellular) { .cellular } else if path.usesInterfaceType(.wiredEthernet) {
                .wired
            } else { .other }
        self.init(
            isOnline: path.status == .satisfied, connectionType: type, isExpensive: path.isExpensive,
            isConstrained: path.isConstrained)
    }
}
