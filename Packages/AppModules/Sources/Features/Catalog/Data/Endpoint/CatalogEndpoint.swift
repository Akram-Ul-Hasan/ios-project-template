import Core
import Foundation

/// The catalog API. Browsing is public, so no endpoint here needs a token.
public enum CatalogEndpoint: Endpoint {
    case products(page: Int, limit: Int, query: String?)
    case productDetails(id: String)

    public var path: String {
        switch self {
        case .products: "/v1/products"
        case .productDetails(let id): "/v1/products/\(id)"
        }
    }

    public var method: HTTPMethod { .get }

    public var query: [URLQueryItem] {
        switch self {
        case .products(let page, let limit, let query):
            [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit))]
                + (query.map { [URLQueryItem(name: "q", value: $0)] } ?? [])
        case .productDetails:
            []
        }
    }

    public var requiresAuth: Bool { false }
}
