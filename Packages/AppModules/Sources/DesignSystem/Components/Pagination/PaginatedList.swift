import Core
import SwiftUI

/// A paged vertical list in about one line (§6e):
/// ```
/// PaginatedList(viewModel.products, onRefresh: { await viewModel.refresh() }) { product in
///     ProductRow(product: product)
/// }
/// ```
/// `onRefresh` should call the view model, which reports refresh failures as a snackbar.
public struct PaginatedList<Item: Identifiable & Equatable & Sendable, Row: View, Loading: View>: View {
    private let viewModel: PaginatedViewModel<Item>
    private let emptyState: EmptyStateView
    private let onRefresh: (@MainActor () async -> Void)?
    private let spacing: CGFloat
    private let loading: Loading
    private let row: (Item) -> Row

    public init(
        _ viewModel: PaginatedViewModel<Item>,
        emptyState: EmptyStateView = EmptyStateView(),
        spacing: CGFloat = AppSpacing.s12,
        onRefresh: (@MainActor () async -> Void)? = nil,
        @ViewBuilder loading: () -> Loading,
        @ViewBuilder row: @escaping (Item) -> Row
    ) {
        self.viewModel = viewModel
        self.emptyState = emptyState
        self.spacing = spacing
        self.onRefresh = onRefresh
        self.loading = loading()
        self.row = row
    }

    public var body: some View {
        PaginatedScaffold(viewModel: viewModel, emptyState: emptyState, onRefresh: onRefresh, loading: loading) {
            footer in
            ScrollView {
                LazyVStack(spacing: spacing) {
                    ForEach(viewModel.items) { item in
                        row(item).paginationTrigger(item, in: viewModel)
                    }
                    footer
                }
                .padding(AppSpacing.s16)
            }
        }
    }
}

extension PaginatedList where Loading == LoadingView {
    public init(
        _ viewModel: PaginatedViewModel<Item>,
        emptyState: EmptyStateView = EmptyStateView(),
        spacing: CGFloat = AppSpacing.s12,
        onRefresh: (@MainActor () async -> Void)? = nil,
        @ViewBuilder row: @escaping (Item) -> Row
    ) {
        self.init(
            viewModel, emptyState: emptyState, spacing: spacing, onRefresh: onRefresh, loading: { LoadingView() },
            row: row)
    }
}
