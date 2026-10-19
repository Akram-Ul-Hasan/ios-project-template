import AppTrackingTransparency

/// App Tracking Transparency. Only ask if the app really tracks (§6l); request while the app is active.
public struct TrackingPermissionHandler: PermissionHandler {
    public init() {}

    public func status() async -> PermissionStatus {
        Self.map(ATTrackingManager.trackingAuthorizationStatus)
    }

    public func request() async -> PermissionStatus {
        Self.map(await ATTrackingManager.requestTrackingAuthorization())
    }

    static func map(_ status: ATTrackingManager.AuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .granted
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .denied
        }
    }
}
