/// Thrown by DTO → entity mappers when a response breaks a domain invariant (§3a).
/// Paths and reasons only, never values, so the detail is safe to log.
public enum MappingError: Error, Equatable, Sendable {
    case missingField(String)
    case invalidValue(String, String)

    public var detail: String {
        switch self {
        case .missingField(let path): "missing \(path)"
        case .invalidValue(let path, let reason): "\(path): \(reason)"
        }
    }
}
