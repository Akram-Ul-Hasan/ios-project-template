import Foundation
import Testing

@testable import ProjectTemplate

@Suite("DeepLinkParser")
@MainActor
struct DeepLinkParserTests {
    @Test(
        "Valid links from the URL scheme and universal links",
        arguments: [
            ("projecttemplate://product/123", DeepLink.product(id: "123")),
            ("projecttemplate://order/A-1024", .order(id: "A-1024")),
            ("projecttemplate://cart", .cart),
            ("projecttemplate://orders", .orders),
            ("projecttemplate://settings", .settings),
            ("https://example.com/product/p_9", .product(id: "p_9")),
            ("https://www.example.com/order/77", .order(id: "77")),
            ("PROJECTTEMPLATE://Product/5", .product(id: "5")),
        ])
    func valid(url: String, expected: DeepLink) throws {
        #expect(DeepLinkParser.parse(try #require(URL(string: url))) == expected)
    }

    @Test(
        "Anything outside the allowlist is rejected",
        arguments: [
            "https://evil.com/product/1",
            "http://example.com/product/1",
            "otherapp://product/1",
            "projecttemplate://product",
            "projecttemplate://product/1/extra",
            "projecttemplate://product/has%20space",
            "projecttemplate://product/\(String(repeating: "a", count: 65))",
            "projecttemplate://checkout/pay",
            "projecttemplate://",
        ])
    func rejected(url: String) throws {
        #expect(DeepLinkParser.parse(try #require(URL(string: url))) == nil)
    }

    @Test("Push payloads use the same parser")
    func push() {
        #expect(DeepLinkParser.parse(pushLink: "projecttemplate://order/9") == .order(id: "9"))
        #expect(DeepLinkParser.parse(pushLink: nil) == nil)
        #expect(DeepLinkParser.parse(pushLink: "not a url") == nil)
    }

    @Test("A link maps to its tab and full back stack")
    func mapping() {
        #expect(DeepLink.order(id: "9").tab == .account)
        #expect(DeepLink.order(id: "9").routes == [.orders, .orderDetails(id: "9")])
        #expect(DeepLink.product(id: "1").requiresAuth == false)
    }

    @Test("The router opens a link with its stack and closes any sheet")
    func routerOpen() {
        let router = AppRouter()
        router.present(.filter)
        router.push(.productDetails(id: "1"))
        router.open(.order(id: "9"))
        #expect(router.selectedTab == .account)
        #expect(router.paths[.account] == [.orders, .orderDetails(id: "9")])
        #expect(router.paths[.home] == [.productDetails(id: "1")])
        #expect(router.sheet == nil)
    }
}
