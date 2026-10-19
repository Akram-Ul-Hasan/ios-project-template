/// Strips secrets from any string before it is logged (§6l): bearer tokens, JWTs, passwords, OTPs, card numbers.
public enum LogRedactor {
    public static let placeholder = "<redacted>"

    /// JSON / form / query keys whose values are never logged.
    static let sensitiveKeys = [
        "password", "new_password", "old_password", "otp", "pin", "cvv", "card_number",
        "access_token", "refresh_token", "token", "secret", "authorization",
    ]

    public static func redact(_ text: String) -> String {
        var result = text
        let keys = sensitiveKeys.joined(separator: "|")

        // "password": "hunter2"  →  "password": "<redacted>"
        if let json = try? Regex(#"("(?:"# + keys + #")"\s*:\s*)"(?:[^"\\]|\\.)*""#).ignoresCase() {
            result.replace(json) { "\($0.output[1].substring ?? "")\"\(placeholder)\"" }
        }
        // password=hunter2  →  password=<redacted>   (form bodies, query strings)
        if let form = try? Regex(#"((?:^|[?&\s])(?:"# + keys + #")=)[^&\s]*"#).ignoresCase() {
            result.replace(form) { "\($0.output[1].substring ?? "")\(placeholder)" }
        }
        result.replace(#/(?i)bearer\s+[A-Za-z0-9\-._~+\/]+=*/#) { _ in "Bearer \(placeholder)" }
        result.replace(#/eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+/#) { _ in placeholder }
        result.replace(#/\b(?:\d[ \-]?){12,18}\d\b/#) { _ in placeholder }
        return result
    }
}
