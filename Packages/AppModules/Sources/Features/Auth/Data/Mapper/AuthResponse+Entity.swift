import AuthDomain
import Core
import Foundation

extension UserResponse {
    /// Validates invariants, then builds the entity (§3a). Never defaults an id, name or phone.
    public func toEntity() throws(MappingError) -> UserEntity {
        guard !id.isEmpty else { throw .invalidValue("user.id", "empty") }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw .invalidValue("user.name", "empty") }
        guard !phone.isEmpty else { throw .invalidValue("user.phone", "empty") }
        return UserEntity(
            id: id,
            name: name,
            phone: phone,
            // An empty email means the same as no email.
            email: email?.isEmpty == false ? email : nil,
            // Display-only: an unusable URL means the same as no photo (initials are shown).
            avatarURL: avatarUrl.flatMap(URL.init(string:))
        )
    }
}

extension TokenResponse {
    public func toEntity() throws(MappingError) -> AuthTokensEntity {
        guard !accessToken.isEmpty else { throw .invalidValue("access_token", "empty") }
        guard !refreshToken.isEmpty else { throw .invalidValue("refresh_token", "empty") }
        return AuthTokensEntity(accessToken: accessToken, refreshToken: refreshToken)
    }
}

extension LoginResponse {
    public func toEntities() throws(MappingError) -> (tokens: AuthTokensEntity, user: UserEntity) {
        let tokens = try TokenResponse(accessToken: accessToken, refreshToken: refreshToken).toEntity()
        return (tokens, try user.toEntity())
    }
}
