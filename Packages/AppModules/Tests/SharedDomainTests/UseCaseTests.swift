import Testing

@testable import SharedDomain

@Suite("UseCase")
struct UseCaseTests {
    private struct Doubler: UseCase {
        func callAsFunction(_ input: Int) async throws -> Int { input * 2 }
    }

    private struct Answer: UseCase {
        func callAsFunction(_ input: Void) async throws -> Int { 42 }
    }

    @Test("Use cases are called like functions")
    func callAsFunction() async throws {
        #expect(try await Doubler()(21) == 42)
    }

    @Test("Void-input use cases need no argument")
    func voidInput() async throws {
        #expect(try await Answer()() == 42)
    }
}
