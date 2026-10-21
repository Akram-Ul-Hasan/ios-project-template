import Core
import Foundation

public enum __Feature__Endpoint: Endpoint {
    case items(page: Int, limit: Int)

    // TODO(__Feature__): use the real path from the API spec.
    public var path: String {
        switch self {
        case .items: "/v1/__feature_lower__"
        }
    }

    public var method: HTTPMethod { .get }

    public var query: [URLQueryItem] {
        switch self {
        case .items(let page, let limit):
            [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit))]
        }
    }
}
