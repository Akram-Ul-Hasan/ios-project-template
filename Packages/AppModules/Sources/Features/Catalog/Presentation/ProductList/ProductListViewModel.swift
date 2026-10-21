import CatalogDomain
import Core
import Observation
import SharedDomain
import os

@MainActor
@Observable
public final class ProductListViewModel: ErrorHandling {
    /// Bound to the search field; the screen debounces it and calls `search()`.
    public var query = ""
    public private(set) var products: PaginatedViewModel<ProductEntity>

    @ObservationIgnored public let errorHandler: ErrorHandler
    @ObservationIgnored private let getProducts: GetProductsUseCase
    @ObservationIgnored private let onProductTap: @MainActor (String) -> Void
    @ObservationIgnored private var activeQuery: String?

    public init(
        getProducts: GetProductsUseCase,
        errorHandler: ErrorHandler,
        onProductTap: @escaping @MainActor (String) -> Void
    ) {
        self.getProducts = getProducts
        self.errorHandler = errorHandler
        self.onProductTap = onProductTap
        products = Self.makeList(getProducts: getProducts, query: nil)
    }

    /// Starts a fresh paged list for the current query. Same query twice is a no-op.
    public func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.isEmpty ? nil : trimmed
        guard normalized != activeQuery else { return }
        activeQuery = normalized
        products = Self.makeList(getProducts: getProducts, query: normalized)
        await products.loadFirst()
    }

    /// Pull to refresh: old products stay visible; a failure is a snackbar (§6m).
    public func refresh() async {
        do {
            try await products.refresh()
        } catch {
            handle(error, context: .refresh) { [weak self] in Task { await self?.refresh() } }
        }
    }

    public func select(_ product: ProductEntity) {
        onProductTap(product.id)
    }

    /// First-page failures are shown by `PaginatedGrid` itself; this is only reached for other contexts.
    public func showFailure(_ error: ResponseError) {
        errorHandler.feedback.show(error: error)
    }

    private static func makeList(getProducts: GetProductsUseCase, query: String?) -> PaginatedViewModel<ProductEntity> {
        PaginatedViewModel { pagination in
            try await getProducts(ProductListInputEntity(query: query, pagination: pagination))
        }
    }

    #if DEBUG
        deinit { AppLogger.lifecycle.debug("deinit ProductListViewModel") }
    #endif
}
