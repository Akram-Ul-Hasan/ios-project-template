import Testing

@testable import Core

@Suite("ViewState")
struct ViewStateTests {
    @Test("Accessors expose exactly one case's payload")
    func accessors() {
        let success = ViewState<Int>.success(3)
        let failure = ViewState<Int>.failure(.network)
        #expect(success.value == 3 && success.error == nil && !success.isLoading)
        #expect(failure.value == nil && failure.error == .network)
        #expect(ViewState<Int>.loading.isLoading)
        #expect(ViewState<Int>.idle.value == nil)
    }
}
