/// Mirrors the API contract (§3a): required fields are non-optional, so a missing one fails decoding.
public struct LoginResponse: Decodable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let user: UserResponse
}

public struct TokenResponse: Decodable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
}

public struct UserResponse: Decodable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let phone: String
    /// Spec: nullable.
    public let email: String?
    /// Spec: nullable.
    public let avatarUrl: String?
}
