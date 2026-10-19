/// Forward-compatible string enums: a raw value the app doesn't know decodes to `.unknown(raw)`
/// instead of failing the whole response (§3a). Implement `init(rawValue:)` with a `default: .unknown(raw)`.
public protocol UnknownCase: Codable, Sendable {
    init(rawValue: String)
    var rawValue: String { get }
}

extension UnknownCase {
    public init(from decoder: any Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
