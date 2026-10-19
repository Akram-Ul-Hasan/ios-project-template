/// One status vocabulary for every Apple permission API.
public enum PermissionStatus: Equatable, Sendable {
    case notDetermined
    case granted
    /// Partial access: selected photos, approximate location, provisional notifications, selected contacts.
    case limited
    case denied
    /// Blocked by parental controls or MDM; the user can't change it.
    case restricted

    /// The feature can be used (fully or partially).
    public var isUsable: Bool { self == .granted || self == .limited }
}
