import Core
import Foundation

/// Mirrors the API contract (§3a). Money is `Decimal`, never `Double`.
public struct ProductResponse: Decodable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let price: Decimal
    /// Spec: nullable (no discount).
    public let discountPrice: Decimal?
    /// Spec: nullable.
    public let imageUrl: String?
    /// Spec: optional.
    public let tags: [String]?
    public let status: ProductStatusResponse
}

public struct ProductDetailsResponse: Decodable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let price: Decimal
    public let discountPrice: Decimal?
    public let imageUrl: String?
    public let tags: [String]?
    public let status: ProductStatusResponse
    public let description: String
    /// Spec: optional gallery.
    public let images: [String]?
    public let stock: Int
}

/// `{ "items": [...], "page": 1, "has_next": true }`
public struct PaginatedResponse<Item: Decodable & Sendable>: Decodable, Sendable {
    public let items: [Item]
    public let page: Int
    public let hasNext: Bool
}

/// Forward-compatible: a new status from the backend decodes to `.unknown(raw)` instead of failing the list.
public enum ProductStatusResponse: UnknownCase, Equatable {
    case active
    case outOfStock
    case discontinued
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "active": self = .active
        case "out_of_stock": self = .outOfStock
        case "discontinued": self = .discontinued
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .active: "active"
        case .outOfStock: "out_of_stock"
        case .discontinued: "discontinued"
        case .unknown(let raw): raw
        }
    }
}
