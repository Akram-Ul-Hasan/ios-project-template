import Testing
@testable import Core

@Suite("Core")
struct CoreTests {
    @Test("Core module links into the test bundle")
    func moduleLinks() {
        #expect(Bool(true))
    }
}
