import CatalogDomain
import Core
import Foundation
import SharedDomain

extension ProductResponse {
    /// Validates the invariants, then builds the entity (§3a). Ids, money and status are never defaulted.
    public func toEntity() throws(MappingError) -> ProductEntity {
        try ProductInvariants.check(id: id, name: name, price: price, discountPrice: discountPrice)
        return ProductEntity(
            id: id,
            name: name,
            price: price,
            discountPrice: discountPrice,
            // Display-only: an unusable URL means the same as no image (placeholder is shown).
            imageURL: imageUrl.flatMap(URL.init(string:)),
            // No tags and an empty tag list mean the same thing.
            tags: tags ?? [],
            status: status.toEntity()
        )
    }
}

extension ProductDetailsResponse {
    public func toEntity() throws(MappingError) -> ProductDetailsEntity {
        try ProductInvariants.check(id: id, name: name, price: price, discountPrice: discountPrice)
        guard stock >= 0 else { throw .invalidValue("product.stock", "negative") }
        let product = ProductEntity(
            id: id, name: name, price: price, discountPrice: discountPrice,
            imageURL: imageUrl.flatMap(URL.init(string:)), tags: tags ?? [], status: status.toEntity())
        return ProductDetailsEntity(
            product: product,
            description: description,
            // Display-only gallery: unusable URLs are skipped, no images means an empty gallery.
            imageURLs: (images ?? []).compactMap(URL.init(string:)),
            stock: stock
        )
    }
}

extension PaginatedResponse where Item == ProductResponse {
    public func toEntity() throws(MappingError) -> PaginatedEntity<ProductEntity> {
        guard page >= 1 else { throw .invalidValue("page", "less than 1") }
        var products: [ProductEntity] = []
        for item in items {
            products.append(try item.toEntity())
        }
        return PaginatedEntity(items: products, page: page, hasNext: hasNext)
    }
}

extension ProductStatusResponse {
    func toEntity() -> ProductStatus {
        switch self {
        case .active: .active
        case .outOfStock: .outOfStock
        case .discontinued: .discontinued
        case .unknown(let raw): .unknown(raw)
        }
    }

    init(_ status: ProductStatus) {
        switch status {
        case .active: self = .active
        case .outOfStock: self = .outOfStock
        case .discontinued: self = .discontinued
        case .unknown(let raw): self = .unknown(raw)
        }
    }
}

enum ProductInvariants {
    static func check(id: String, name: String, price: Decimal, discountPrice: Decimal?) throws(MappingError) {
        guard !id.isEmpty else { throw .invalidValue("product.id", "empty") }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw .invalidValue("product.name", "empty") }
        guard price >= 0 else { throw .invalidValue("product.price", "negative") }
        if let discountPrice {
            guard discountPrice >= 0 else { throw .invalidValue("product.discountPrice", "negative") }
            guard discountPrice <= price else { throw .invalidValue("product.discountPrice", "greater than price") }
        }
    }
}
