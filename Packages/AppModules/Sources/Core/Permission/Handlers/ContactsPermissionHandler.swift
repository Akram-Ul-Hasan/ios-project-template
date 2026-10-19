import Contacts

public struct ContactsPermissionHandler: PermissionHandler {
    public init() {}

    public func status() async -> PermissionStatus {
        Self.map(CNContactStore.authorizationStatus(for: .contacts))
    }

    public func request() async -> PermissionStatus {
        guard CNContactStore.authorizationStatus(for: .contacts) == .notDetermined else { return await status() }
        _ = try? await CNContactStore().requestAccess(for: .contacts)
        return await status()
    }

    static func map(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .granted
        case .denied: .denied
        case .restricted: .restricted
        // `.limited` (iOS 18+): the user shared selected contacts.
        default: .limited
        }
    }
}
