import Core
import Localization
import SwiftUI

/// What `PaginatedList` and `PaginatedGrid` share: first-load skeleton, empty and error states,
/// the bottom spinner / retry row, pull to refresh, and auto-retry when the connection returns.
struct PaginatedScaffold<Item: Identifiable & Equatable & Sendable, Loading: View, Content: View>: View {
    let viewModel: PaginatedViewModel<Item>
    let emptyState: EmptyStateView
    let onRefresh: (@MainActor () async -> Void)?
    let loading: Loading
    @ViewBuilder let content: (_ footer: PaginationFooter<Item>) -> Content

    @Environment(NetworkMonitor.self) private var network: NetworkMonitor?

    var body: some View {
        Group {
            switch viewModel.phase {
            case .idle, .loadingFirst:
                loading
            case .failure(let error):
                centered(EmptyStateView(error: error) { Task { await viewModel.loadFirst() } })
            case .empty:
                centered(emptyState)
            case .loaded, .loadingMore, .failureMore:
                content(PaginationFooter(viewModel: viewModel))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await viewModel.loadFirst() }
        .refreshable(action: onRefresh)
        .onChange(of: network?.isOnline) { wasOnline, isOnline in
            guard wasOnline == false, isOnline == true, viewModel.phase == .failure(.network) else { return }
            Task { await viewModel.loadFirst() }
        }
    }

    private func centered(_ view: EmptyStateView) -> some View {
        ScrollView { view.containerRelativeFrame([.horizontal, .vertical]) }
    }
}

/// Spinner while the next page loads; a tappable retry row if it failed.
struct PaginationFooter<Item: Identifiable & Equatable & Sendable>: View {
    let viewModel: PaginatedViewModel<Item>

    var body: some View {
        switch viewModel.phase {
        case .loadingMore:
            ProgressView()
                .tint(AppColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.s16)
        case .failureMore:
            TapArea {
                Task { await viewModel.retryMore() }
            } label: {
                Label(L10n.Pagination.loadMoreFailed, systemImage: "arrow.clockwise")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.s16)
            }
        default:
            EmptyView()
        }
    }
}

extension View {
    /// Asks for the next page as rows appear near the end.
    func paginationTrigger<Item: Identifiable & Equatable & Sendable>(
        _ item: Item,
        in viewModel: PaginatedViewModel<Item>
    ) -> some View {
        // An unstructured task: a row scrolling away must not cancel the page request.
        onAppear { Task { await viewModel.loadMoreIfNeeded(currentItem: item) } }
    }
}
