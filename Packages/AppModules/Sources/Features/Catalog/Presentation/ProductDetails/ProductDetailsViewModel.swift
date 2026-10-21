import CatalogDomain
import Core
import Observation
import os

@MainActor
@Observable
public final class ProductDetailsViewModel: ErrorHandling, StateReporting {
    public private(set) var state: ViewState<ProductDetailsEntity> = .idle {
        didSet { transition(to: state) }
    }

    @ObservationIgnored public let errorHandler: ErrorHandler
    @ObservationIgnored private let productID: String
    @ObservationIgnored private let getDetails: GetProductDetailsUseCase

    public init(productID: String, getDetails: GetProductDetailsUseCase, errorHandler: ErrorHandler) {
        self.productID = productID
        self.getDetails = getDetails
        self.errorHandler = errorHandler
    }

    public func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .success(try await getDetails(productID))
        } catch {
            handle(error, context: .initialLoad)
        }
    }

    /// Keeps the details on screen; a failure is a snackbar.
    public func refresh() async {
        do {
            state = .success(try await getDetails(productID))
        } catch {
            handle(error, context: .refresh) { [weak self] in Task { await self?.refresh() } }
        }
    }

    public func showFailure(_ error: ResponseError) {
        state = .failure(error)
    }

    #if DEBUG
        deinit { AppLogger.lifecycle.debug("deinit ProductDetailsViewModel") }
    #endif
}
