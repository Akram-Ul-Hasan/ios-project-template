import Foundation
import Testing

@testable import DesignSystem

@Suite("AppWebView allowlist")
@MainActor
struct AppWebViewTests {
    private let hosts: Set<String> = ["example.com"]

    @Test(
        "Only HTTPS pages on allowed hosts load inside",
        arguments: [
            ("https://example.com/terms", true),
            ("https://help.example.com/a", true),
            ("https://EXAMPLE.com", true),
            ("http://example.com/terms", false),
            ("https://example.com.evil.io", false),
            ("https://notexample.com", false),
            ("tel:+8801700000000", false),
            ("about:blank", true),
        ])
    func allowlist(url: String, allowed: Bool) throws {
        #expect(AppWebView.isAllowed(try #require(URL(string: url)), hosts: hosts) == allowed)
    }
}
