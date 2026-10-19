import SwiftUI
import WebKit

/// In-app web pages (terms, help, payment return pages) with a navigation allowlist (§6l):
/// only HTTPS pages on `allowedHosts` (and their subdomains) load inside; every other link opens in the browser.
/// No JavaScript bridge is exposed, so untrusted pages can't call into the app.
public struct AppWebView: View {
    private let url: URL
    private let allowedHosts: Set<String>
    @Environment(\.openURL) private var openURL
    @State private var isLoading = true

    public init(url: URL, allowedHosts: Set<String>) {
        self.url = url
        self.allowedHosts = allowedHosts
    }

    public var body: some View {
        WebViewRepresentable(url: url, allowedHosts: allowedHosts, isLoading: $isLoading) { openURL($0) }
            .overlay {
                if isLoading { ProgressView().tint(AppColors.brandPrimary) }
            }
    }

    /// Whether `url` may load inside the web view.
    static func isAllowed(_ url: URL, hosts: Set<String>) -> Bool {
        if url.absoluteString == "about:blank" { return true }
        guard url.scheme == "https", let host = url.host()?.lowercased() else { return false }
        return hosts.contains { host == $0 || host.hasSuffix(".\($0)") }
    }
}

@MainActor
final class WebViewCoordinator: NSObject, WKNavigationDelegate {
    let allowedHosts: Set<String>
    let isLoading: Binding<Bool>
    let openExternally: (URL) -> Void

    init(allowedHosts: Set<String>, isLoading: Binding<Bool>, openExternally: @escaping (URL) -> Void) {
        self.allowedHosts = allowedHosts
        self.isLoading = isLoading
        self.openExternally = openExternally
    }

    func makeWebView(loading url: URL) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.navigationDelegate = self
        if AppWebView.isAllowed(url, hosts: allowedHosts) { webView.load(URLRequest(url: url)) }
        return webView
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async
        -> WKNavigationActionPolicy
    {
        guard let url = navigationAction.request.url else { return .cancel }
        if AppWebView.isAllowed(url, hosts: allowedHosts) { return .allow }
        if ["http", "https", "tel", "mailto"].contains(url.scheme ?? "") { openExternally(url) }
        return .cancel
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
        isLoading.wrappedValue = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        isLoading.wrappedValue = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: any Error) {
        isLoading.wrappedValue = false
    }

    func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: any Error
    ) {
        isLoading.wrappedValue = false
    }
}

#if os(iOS)
    private struct WebViewRepresentable: UIViewRepresentable {
        let url: URL
        let allowedHosts: Set<String>
        @Binding var isLoading: Bool
        let openExternally: (URL) -> Void

        func makeCoordinator() -> WebViewCoordinator {
            WebViewCoordinator(allowedHosts: allowedHosts, isLoading: $isLoading, openExternally: openExternally)
        }

        func makeUIView(context: Context) -> WKWebView { context.coordinator.makeWebView(loading: url) }
        func updateUIView(_ webView: WKWebView, context: Context) {}
    }
#else
    private struct WebViewRepresentable: NSViewRepresentable {
        let url: URL
        let allowedHosts: Set<String>
        @Binding var isLoading: Bool
        let openExternally: (URL) -> Void

        func makeCoordinator() -> WebViewCoordinator {
            WebViewCoordinator(allowedHosts: allowedHosts, isLoading: $isLoading, openExternally: openExternally)
        }

        func makeNSView(context: Context) -> WKWebView { context.coordinator.makeWebView(loading: url) }
        func updateNSView(_ webView: WKWebView, context: Context) {}
    }
#endif

#Preview {
    if let url = URL(string: "https://www.apple.com/legal/") {
        AppWebView(url: url, allowedHosts: ["apple.com"])
    }
}
