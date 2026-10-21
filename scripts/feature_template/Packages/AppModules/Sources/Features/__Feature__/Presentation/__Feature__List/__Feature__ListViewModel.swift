import Core
import Observation
import SharedDomain
import __Feature__Domain
import os

@MainActor
@Observable
public final class __Feature__ListViewModel: ErrorHandling {
    public let items: PaginatedViewModel<__Feature__ItemEntity>

    @ObservationIgnored public let errorHandler: ErrorHandler
    @ObservationIgnored private let onItemTap: @MainActor (String) -> Void

    public init(
        getItems: Get__Feature__ItemsUseCase,
        errorHandler: ErrorHandler,
        onItemTap: @escaping @MainActor (String) -> Void
    ) {
        self.errorHandler = errorHandler
        self.onItemTap = onItemTap
        items = PaginatedViewModel { try await getItems($0) }
    }

    public func refresh() async {
        do {
            try await items.refresh()
        } catch {
            handle(error, context: .refresh) { [weak self] in Task { await self?.refresh() } }
        }
    }

    public func select(_ item: __Feature__ItemEntity) {
        onItemTap(item.id)
    }

    public func showFailure(_ error: ResponseError) {
        errorHandler.feedback.show(error: error)
    }

    #if DEBUG
        deinit { AppLogger.lifecycle.debug("deinit __Feature__ListViewModel") }
    #endif
}
