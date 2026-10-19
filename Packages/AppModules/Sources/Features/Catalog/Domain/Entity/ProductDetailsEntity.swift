import Foundation
import SharedDomain

/// Everything the details screen shows. The shared `ProductEntity` plus details-only fields.
public struct ProductDetailsEntity: Equatable, Sendable {
    public let product: ProductEntity
    public let description: String
    /// Gallery; empty = only the main image.
    public let imageURLs: [URL]
    public let stock: Int

    public init(product: ProductEntity, description: String, imageURLs: [URL], stock: Int) {
        self.product = product
        self.description = description
        self.imageURLs = imageURLs
        self.stock = stock
    }
}
