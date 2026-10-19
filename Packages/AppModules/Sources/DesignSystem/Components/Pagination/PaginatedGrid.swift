import Core
import SwiftUI

/// A paged adaptive grid: 2 columns on iPhone, more on iPad and in landscape, from one layout (§2a).
public struct PaginatedGrid<Item: Identifiable & Equatable & Sendable, Cell: View, Loading: View>: View {
    private let viewModel: PaginatedViewModel<Item>
    private let emptyState: EmptyStateView
    private let onRefresh: (@MainActor () async -> Void)?
    private let minItemWidth: CGFloat
    private let loading: Loading
    private let cell: (Item) -> Cell

    public init(
        _ viewModel: PaginatedViewModel<Item>,
        emptyState: EmptyStateView = EmptyStateView(),
        minItemWidth: CGFloat = AppSize.gridItemMinWidth,
        onRefresh: (@MainActor () async -> Void)? = nil,
        @ViewBuilder loading: () -> Loading,
        @ViewBuilder cell: @escaping (Item) -> Cell
    ) {
        self.viewModel = viewModel
        self.emptyState = emptyState
        self.minItemWidth = minItemWidth
        self.onRefresh = onRefresh
        self.loading = loading()
        self.cell = cell
    }

    public var body: some View {
        PaginatedScaffold(viewModel: viewModel, emptyState: emptyState, onRefresh: onRefresh, loading: loading) {
            footer in
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: minItemWidth), spacing: AppSpacing.s12)],
                    spacing: AppSpacing.s12
                ) {
                    ForEach(viewModel.items) { item in
                        cell(item).paginationTrigger(item, in: viewModel)
                    }
                }
                .padding(AppSpacing.s16)
                footer
            }
        }
    }
}

extension PaginatedGrid where Loading == LoadingView {
    public init(
        _ viewModel: PaginatedViewModel<Item>,
        emptyState: EmptyStateView = EmptyStateView(),
        minItemWidth: CGFloat = AppSize.gridItemMinWidth,
        onRefresh: (@MainActor () async -> Void)? = nil,
        @ViewBuilder cell: @escaping (Item) -> Cell
    ) {
        self.init(
            viewModel, emptyState: emptyState, minItemWidth: minItemWidth, onRefresh: onRefresh,
            loading: { LoadingView() }, cell: cell)
    }
}
