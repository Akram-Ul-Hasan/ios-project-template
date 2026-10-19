import Testing

@testable import ProjectTemplate

@Suite("AppRouter")
@MainActor
struct AppRouterTests {
    @Test("Each tab keeps its own stack")
    func perTabStacks() {
        let router = AppRouter()
        router.push(.productDetails(id: "1"))
        router.select(.account)
        router.push(.orders)
        router.push(.orderDetails(id: "9"))
        #expect(router.paths[.home] == [.productDetails(id: "1")])
        #expect(router.paths[.account] == [.orders, .orderDetails(id: "9")])
        router.pop()
        #expect(router.paths[.account] == [.orders])
    }

    @Test("Re-selecting the current tab pops to root; other tabs keep their history")
    func reselect() {
        let router = AppRouter()
        router.push(.productDetails(id: "1"))
        router.select(.cart)
        router.select(.home)
        #expect(router.paths[.home] == [.productDetails(id: "1")])
        router.select(.home)
        #expect(router.paths[.home] == [])
    }

    @Test("Sheets and reset")
    func sheetsAndReset() {
        let router = AppRouter()
        router.present(.filter)
        #expect(router.sheet == .filter)
        router.select(.account)
        router.push(.settings)
        router.reset()
        #expect(router.selectedTab == .home && router.paths.isEmpty && router.sheet == nil)
    }
}
