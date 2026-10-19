import Foundation

/// A product as every feature sees it (catalog, cart, wishlist, ProductCard). Data only (rule 1).
public struct ProductEntity: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    /// Money is `Decimal`, never `Double`.
    public let price: Decimal
    /// `nil` = no discount.
    public let discountPrice: Decimal?
    /// `nil` = the product has no image; the UI shows its placeholder.
    public let imageURL: URL?
    public let tags: [String]
    public let status: ProductStatus

    public init(
        id: String,
        name: String,
        price: Decimal,
        discountPrice: Decimal?,
        imageURL: URL?,
        tags: [String],
        status: ProductStatus
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.discountPrice = discountPrice
        self.imageURL = imageURL
        self.tags = tags
        self.status = status
    }
}

/// Forward-compatible: a status the app doesn't know yet arrives as `.unknown(raw)` instead of failing the screen.
public enum ProductStatus: Equatable, Sendable {
    case active
    case outOfStock
    case discontinued
    case unknown(String)
}
