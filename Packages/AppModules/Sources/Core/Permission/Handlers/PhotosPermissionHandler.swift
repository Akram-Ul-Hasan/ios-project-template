import Photos

/// Photo library read/write. "Selected photos" maps to `.limited`.
public struct PhotosPermissionHandler: PermissionHandler {
    public init() {}

    public func status() async -> PermissionStatus {
        Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    public func request() async -> PermissionStatus {
        Self.map(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
    }

    static func map(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .granted
        case .limited: .limited
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .denied
        }
    }
}
