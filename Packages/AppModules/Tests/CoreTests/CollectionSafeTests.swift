import Testing

@testable import Core

@Suite("Collection[safe:]")
struct CollectionSafeTests {
    @Test("Returns the element in range and nil outside it")
    func safe() {
        let items = [10, 20, 30]
        #expect(items[safe: 1] == 20)
        #expect(items[safe: 3] == nil)
        #expect(items[safe: -1] == nil)
        #expect([Int]()[safe: 0] == nil)
    }
}
