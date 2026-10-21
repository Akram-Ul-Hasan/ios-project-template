/// `POST /v1/auth/login` body, exactly the API's shape.
public struct LoginRequest: Encodable, Equatable, Sendable {
    public let phone: String
    public let password: String

    public init(phone: String, password: String) {
        self.phone = phone
        self.password = password
    }
}

/// `POST /v1/auth/refresh` body.
public struct RefreshRequest: Encodable, Equatable, Sendable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
