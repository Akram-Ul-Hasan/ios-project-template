import AuthData
import AuthDomain
import Core
import Foundation
import Testing

@Suite("Auth mappers")
struct AuthMapperTests {
    private func decode<T: Decodable>(_ json: String) throws -> T {
        try JSONDecoder.app.decode(T.self, from: Data(json.utf8))
    }

    private let validLogin = #"""
        {"access_token":"a1","refresh_token":"r1",
         "user":{"id":"u1","name":"Rahim","phone":"01712345678","email":"","avatar_url":"https://cdn.test/u1.png"}}
        """#

    @Test("A valid response maps exactly")
    func valid() throws {
        let (tokens, user) = try (decode(validLogin) as LoginResponse).toEntities()
        #expect(tokens == AuthTokensEntity(accessToken: "a1", refreshToken: "r1"))
        #expect(
            user
                == UserEntity(
                    id: "u1", name: "Rahim", phone: "01712345678", email: nil,
                    avatarURL: URL(string: "https://cdn.test/u1.png")))
    }

    @Test("A missing required field fails decoding")
    func missingField() {
        #expect(throws: DecodingError.self) {
            let _: LoginResponse = try decode(#"{"access_token":"a1","user":{"id":"u1","name":"R","phone":"1"}}"#)
        }
    }

    @Test(
        "Each broken invariant throws its MappingError",
        arguments: [
            (#"{"id":"","name":"R","phone":"1"}"#, MappingError.invalidValue("user.id", "empty")),
            (#"{"id":"u1","name":"  ","phone":"1"}"#, .invalidValue("user.name", "empty")),
            (#"{"id":"u1","name":"R","phone":""}"#, .invalidValue("user.phone", "empty")),
        ])
    func userGuards(json: String, expected: MappingError) throws {
        let response: UserResponse = try decode(json)
        #expect(throws: expected) { try response.toEntity() }
    }

    @Test("Empty tokens are rejected")
    func tokenGuards() throws {
        let noAccess: TokenResponse = try decode(#"{"access_token":"","refresh_token":"r"}"#)
        let noRefresh: TokenResponse = try decode(#"{"access_token":"a","refresh_token":""}"#)
        #expect(throws: MappingError.invalidValue("access_token", "empty")) { try noAccess.toEntity() }
        #expect(throws: MappingError.invalidValue("refresh_token", "empty")) { try noRefresh.toEntity() }
    }

    @Test("Optional display fields: null or empty means absent")
    func optionals() throws {
        let response: UserResponse = try decode(#"{"id":"u1","name":"R","phone":"1","email":null,"avatar_url":null}"#)
        let user = try response.toEntity()
        #expect(user.email == nil && user.avatarURL == nil)
    }
}
