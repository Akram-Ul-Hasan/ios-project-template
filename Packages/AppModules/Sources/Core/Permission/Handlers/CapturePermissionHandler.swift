import AVFoundation

/// Camera (`.video`) or microphone (`.audio`).
public struct CapturePermissionHandler: PermissionHandler {
    private let media: AVMediaType

    public init(media: AVMediaType) {
        self.media = media
    }

    public func status() async -> PermissionStatus {
        Self.map(AVCaptureDevice.authorizationStatus(for: media))
    }

    public func request() async -> PermissionStatus {
        guard AVCaptureDevice.authorizationStatus(for: media) == .notDetermined else { return await status() }
        return await AVCaptureDevice.requestAccess(for: media) ? .granted : .denied
    }

    static func map(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .granted
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .denied
        }
    }
}
