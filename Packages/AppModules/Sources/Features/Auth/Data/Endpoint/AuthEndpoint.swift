import Core

/// The auth feature's API. Paths live here, owned by the feature (§6o).
public enum AuthEndpoint: Endpoint {
    case login(LoginRequest)
    case refresh(RefreshRequest)
    case logout

    public var path: String {
        switch self {
        case .login: "/v1/auth/login"
        case .refresh: "/v1/auth/refresh"
        case .logout: "/v1/auth/logout"
        }
    }

    public var method: HTTPMethod { .post }

    public var body: (any Encodable & Sendable)? {
        switch self {
        case .login(let request): request
        case .refresh(let request): request
        case .logout: nil
        }
    }

    /// Login and refresh are how a token is obtained, so they can't need one.
    public var requiresAuth: Bool {
        switch self {
        case .login, .refresh: false
        case .logout: true
        }
    }
}
