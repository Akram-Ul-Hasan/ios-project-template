/// Deep link allowlist (§6c, §6l). The parser rejects any scheme or host not listed here.
public enum DeepLinkConstants {
    /// Custom URL scheme, also registered in Info.plist (`CFBundleURLTypes`).
    public static let urlScheme = "projecttemplate"
    /// Universal link hosts, also listed in the Associated Domains entitlement.
    public static let universalLinkHosts: Set<String> = ["example.com", "www.example.com"]
    /// Key carrying the link in a push payload: `{"deeplink": "projecttemplate://product/123"}`.
    public static let pushPayloadKey = "deeplink"
}
