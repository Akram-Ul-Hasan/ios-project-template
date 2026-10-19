/// Why a value failed a rule. No text: `ErrorMessages` (Core) turns each case into a localized message
/// with its parameters, e.g. `.tooShort(min: 8)` → "At least 8 characters".
public enum ValidationError: Error, Equatable, Sendable {
    case required
    case tooShort(min: Int)
    case tooLong(max: Int)
    case invalidFormat(FieldFormat)
    case mismatch
    case outOfRange
}

/// Formats with their own message ("Enter a valid phone number").
public enum FieldFormat: Equatable, Sendable {
    case phone
    case email
    case otp
    case password
}
