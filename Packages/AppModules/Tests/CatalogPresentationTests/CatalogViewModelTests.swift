import CatalogDomain
import CatalogPresentation
import Core
import Localization
import SharedDomain
import TestSupport
import Testing

@Suite("Catalog view models", .serialized)
@MainActor
struct CatalogViewModelTests {
    private let feedback = MockFeedbackPresenter()
    private var errorHandler: ErrorHandler { ErrorHandler(feedback: feedback, events: SessionEvents()) }

    init() { LocalizationBundle.apply(.en) }

    @Test("Search starts a fresh list; the same query twice does nothing")
    func search() async {
        let repository = FakeCatalogRepository(total: 30)
        let model = ProductListViewModel(
            getProducts: GetProductsUseCase(repository: repository), errorHandler: errorHandler
        ) { _ in }
        await model.products.loadFirst()
        #expect(model.products.items.count == 20)

        model.query = "  Rice "
        await model.search()
        #expect(model.products.items.allSatisfy { $0.name.hasPrefix("Rice") })
        await model.search()
        #expect(repository.queries.withLock { $0 } == [nil, "Rice"])
    }

    @Test("A failed refresh keeps the products and shows a snackbar with Retry")
    func refreshFailure() async {
        let repository = FakeCatalogRepository(total: 5)
        let model = ProductListViewModel(
            getProducts: GetProductsUseCase(repository: repository), errorHandler: errorHandler
        ) { _ in }
        await model.products.loadFirst()
        repository.failure.withLock { $0 = .network }
        await model.refresh()
        #expect(model.products.items.count == 5)
        #expect(feedback.messages.first?.action?.title == L10n.Common.retry)
    }

    @Test("Tapping a product reports its id")
    func select() {
        var tapped: String?
        let model = ProductListViewModel(
            getProducts: GetProductsUseCase(repository: FakeCatalogRepository(total: 1)), errorHandler: errorHandler
        ) { tapped = $0 }
        model.select(FakeCatalogRepository.product(7))
        #expect(tapped == "p7")
    }
}
