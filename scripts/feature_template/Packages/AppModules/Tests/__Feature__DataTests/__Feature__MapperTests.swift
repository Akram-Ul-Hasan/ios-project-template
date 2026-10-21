import Core
import Foundation
import Testing
import __Feature__Data
import __Feature__Domain

@Suite("__Feature__ mappers")
struct __Feature__MapperTests {
    private func item(_ json: String) throws -> __Feature__ItemResponse {
        try JSONDecoder.app.decode(__Feature__ItemResponse.self, from: Data(json.utf8))
    }

    @Test("A valid item maps exactly")
    func valid() throws {
        #expect(try item(#"{"id":"1","title":"First"}"#).toEntity() == __Feature__ItemEntity(id: "1", title: "First"))
    }

    @Test("A missing required field fails decoding")
    func missing() {
        #expect(throws: DecodingError.self) { try item(#"{"id":"1"}"#) }
    }

    @Test(
        "Each broken invariant throws its MappingError",
        arguments: [
            (#"{"id":"","title":"First"}"#, MappingError.invalidValue("__feature_lower__.id", "empty")),
            (#"{"id":"1","title":""}"#, .invalidValue("__feature_lower__.title", "empty")),
        ])
    func guards(json: String, expected: MappingError) throws {
        let response = try item(json)
        #expect(throws: expected) { try response.toEntity() }
    }
}
