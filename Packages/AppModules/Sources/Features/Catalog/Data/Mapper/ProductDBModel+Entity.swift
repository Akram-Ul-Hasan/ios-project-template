import Core
import CoreData
import Foundation
import SharedDomain

extension ProductDBModel {
    /// Tags are stored as one string joined with the ASCII unit separator, which never appears in a tag.
    static let tagSeparator = "\u{1F}"

    /// A corrupted row throws, and the cache treats it as a miss instead of showing defaults (§3a).
    func toEntity() throws(MappingError) -> ProductEntity {
        guard let id, !id.isEmpty else { throw .missingField("cached_product.id") }
        guard let name else { throw .missingField("cached_product.name") }
        guard let price else { throw .missingField("cached_product.price") }
        guard let status else { throw .missingField("cached_product.status") }
        return ProductEntity(
            id: id,
            name: name,
            price: price.decimalValue,
            discountPrice: discountPrice?.decimalValue,
            imageURL: imageURL.flatMap(URL.init(string:)),
            // Stored as "" when the product has no tags.
            tags: tags.map { $0.split(separator: Self.tagSeparator).map(String.init) } ?? [],
            status: ProductStatusResponse(rawValue: status).toEntity()
        )
    }

    func update(from product: ProductEntity, position: Int, cachedAt: Date) {
        id = product.id
        name = product.name
        price = NSDecimalNumber(decimal: product.price)
        discountPrice = product.discountPrice.map { NSDecimalNumber(decimal: $0) }
        imageURL = product.imageURL?.absoluteString
        tags = product.tags.joined(separator: Self.tagSeparator)
        status = ProductStatusResponse(product.status).rawValue
        self.position = Int64(position)
        self.cachedAt = cachedAt
    }
}
