import Core
import Foundation

/// One parser for push payloads, universal links and the custom URL scheme (§6c). Allowlist only:
/// unknown schemes, hosts, paths or malformed ids return `nil`.
///
/// - `projecttemplate://product/123`
/// - `https://example.com/product/123`
/// - push: `{"deeplink": "projecttemplate://order/A-1024"}`
enum DeepLinkParser {
    static func parse(_ url: URL) -> DeepLink? {
        let segments: [String]
        switch url.scheme?.lowercased() {
        case DeepLinkConstants.urlScheme:
            segments = [url.host()].compactMap { $0 } + url.pathComponents.filter { $0 != "/" }
        case "https":
            guard let host = url.host()?.lowercased(), DeepLinkConstants.universalLinkHosts.contains(host) else {
                return nil
            }
            segments = url.pathComponents.filter { $0 != "/" }
        default:
            return nil
        }
        return link(from: segments)
    }

    /// The `deeplink` string from a push payload.
    static func parse(pushLink: String?) -> DeepLink? {
        guard let pushLink, let url = URL(string: pushLink) else { return nil }
        return parse(url)
    }

    private static func link(from segments: [String]) -> DeepLink? {
        guard let first = segments.first?.lowercased() else { return nil }
        let id = segments.count == 2 ? segments.last.flatMap(validID) : nil
        switch (first, segments.count) {
        case ("product", 2): return id.map { .product(id: $0) }
        case ("order", 2): return id.map { .order(id: $0) }
        case ("cart", 1): return .cart
        case ("orders", 1): return .orders
        case ("settings", 1): return .settings
        default: return nil
        }
    }

    /// Ids are 1–64 letters, digits, `-` or `_`; anything else is rejected before it reaches a screen.
    private static func validID(_ id: String) -> String? {
        id.wholeMatch(of: /[A-Za-z0-9_\-]{1,64}/) == nil ? nil : id
    }
}
