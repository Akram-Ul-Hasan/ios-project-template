/// Business limits shared by use cases and the UI (§6o). Infra numbers (timeouts, page size) live in Core.
public enum ValidationConstants {
    public static let otpLength = 6
    public static let passwordMin = 8
    public static let nameMax = 50

    /// Bangladeshi mobile number: 01[3-9] + 8 digits, optional +88 / 88 prefix (+880 1XXXXXXXXX).
    public static var phoneBD: Regex<Substring> { /(?:\+?88)?01[3-9]\d{8}/ }

    /// Pragmatic shape check only; the server is the authority on deliverability.
    public static var email: Regex<Substring> { /[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}/ }
}
