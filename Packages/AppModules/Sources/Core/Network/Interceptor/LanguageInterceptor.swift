import Foundation
import Localization

/// Sends the app language as `Accept-Language`, so backend messages and product names come back in it (§6k).
public struct LanguageInterceptor: RequestInterceptor {
    public init() {}

    public func adapt(_ request: URLRequest, for endpoint: any Endpoint) async throws -> URLRequest {
        var request = request
        request.setValue(LocalizationBundle.language.rawValue, forHTTPHeaderField: "Accept-Language")
        return request
    }
}
