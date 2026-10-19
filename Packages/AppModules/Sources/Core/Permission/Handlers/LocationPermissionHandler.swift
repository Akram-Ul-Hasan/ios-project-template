import CoreLocation

/// When-in-use location. `CLLocationManager` reports through a delegate, wrapped in a continuation here.
public struct LocationPermissionHandler: PermissionHandler {
    public init() {}

    public func status() async -> PermissionStatus {
        await MainActor.run {
            let manager = CLLocationManager()
            return Self.map(
                manager.authorizationStatus, reducedAccuracy: manager.accuracyAuthorization == .reducedAccuracy)
        }
    }

    public func request() async -> PermissionStatus {
        let requester = await LocationAuthorizationRequester()
        let (status, reduced) = await requester.request()
        return Self.map(status, reducedAccuracy: reduced)
    }

    static func map(_ status: CLAuthorizationStatus, reducedAccuracy: Bool) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorizedAlways, .authorizedWhenInUse: return reducedAccuracy ? .limited : .granted
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }
}

@MainActor
private final class LocationAuthorizationRequester: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<(CLAuthorizationStatus, Bool), Never>?

    func request() async -> (CLAuthorizationStatus, Bool) {
        guard manager.authorizationStatus == .notDetermined else {
            return (manager.authorizationStatus, manager.accuracyAuthorization == .reducedAccuracy)
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        // Delivered on the main thread: the manager was created there.
        MainActor.assumeIsolated {
            // Called once immediately with the current (undetermined) status; wait for the user's answer.
            guard manager.authorizationStatus != .notDetermined, let continuation else { return }
            self.continuation = nil
            continuation.resume(
                returning: (manager.authorizationStatus, manager.accuracyAuthorization == .reducedAccuracy))
        }
    }
}
