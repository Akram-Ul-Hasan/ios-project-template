/// Typed backend error codes. Unknown codes decode to `.unknown(raw)` so a new code shows the generic message.
public enum BackendErrorCode: Equatable, Sendable {
    case outOfStock
    case couponExpired
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "OUT_OF_STOCK": self = .outOfStock
        case "COUPON_EXPIRED": self = .couponExpired
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .outOfStock: "OUT_OF_STOCK"
        case .couponExpired: "COUPON_EXPIRED"
        case .unknown(let raw): raw
        }
    }
}

extension BackendErrorCode: Decodable {
    public init(from decoder: any Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }
}
