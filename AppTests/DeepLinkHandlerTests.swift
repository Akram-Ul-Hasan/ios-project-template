import Testing

@testable import ProjectTemplate

@Suite("DeepLinkHandler")
@MainActor
struct DeepLinkHandlerTests {
    @Test("A cold-start link waits until the UI is ready")
    func coldStart() {
        let router = AppRouter()
        let handler = DeepLinkHandler(router: router)
        handler.receive(.product(id: "1"))
        #expect(handler.pending == .product(id: "1"))
        #expect(router.paths.isEmpty)

        handler.update(isReady: true, isSignedIn: true)
        #expect(handler.pending == nil)
        #expect(router.paths[.home] == [.productDetails(id: "1")])
    }

    @Test("A link that needs login waits for sign-in; public links don't")
    func authGate() {
        let router = AppRouter()
        let handler = DeepLinkHandler(router: router)
        handler.update(isReady: true, isSignedIn: false)
        handler.receive(.order(id: "9"))
        #expect(handler.pending == .order(id: "9"))

        handler.update(isReady: true, isSignedIn: true)
        #expect(router.selectedTab == .account)

        handler.update(isReady: true, isSignedIn: false)
        handler.receive(.cart)
        #expect(router.selectedTab == .cart)
    }

    @Test("Unrecognised links are ignored")
    func unknown() {
        let handler = DeepLinkHandler(router: AppRouter())
        handler.receive(nil)
        #expect(handler.pending == nil)
    }
}
