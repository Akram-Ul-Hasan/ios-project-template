import Core
import DesignSystem
import Localization
import SharedDomain
import SwiftUI

/// Searchable, paged product grid. One adaptive layout: 2 columns on iPhone, more on iPad and in landscape.
public struct ProductListScreen: View {
    @State private var viewModel: ProductListViewModel
    private static let searchDebounce: Duration = .milliseconds(300)

    public init(viewModel: ProductListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $viewModel.query, placeholder: L10n.Catalog.searchPlaceholder)
                .padding(.horizontal, AppSpacing.s16)
                .padding(.vertical, AppSpacing.s8)
            PaginatedGrid(
                viewModel.products,
                emptyState: EmptyStateView(
                    systemImage: "magnifyingglass", title: L10n.Catalog.noResults,
                    message: L10n.Catalog.noResultsMessage),
                onRefresh: { await viewModel.refresh() },
                loading: { SkeletonGrid() }
            ) { product in
                ProductCard(product: product) { viewModel.select(product) }
            }
        }
        .background(AppColors.background)
        .commonAppBar(L10n.Catalog.title, showsBack: false)
        // `.task(id:)` cancels the previous wait on every keystroke: a debounce with no extra state (§6n).
        .task(id: viewModel.query) {
            try? await Task.sleep(for: Self.searchDebounce)
            guard !Task.isCancelled else { return }
            await viewModel.search()
        }
    }
}

/// First-load placeholder in the shape of the real grid.
private struct SkeletonGrid: View {
    private static let placeholders = (0..<6).map {
        ProductEntity(
            id: "placeholder-\($0)", name: "Placeholder product name", price: 1000, discountPrice: nil, imageURL: nil,
            tags: [], status: .active)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: AppSize.gridItemMinWidth), spacing: AppSpacing.s12)],
                spacing: AppSpacing.s12
            ) {
                ForEach(Self.placeholders) { product in
                    ProductCard(product: product) {}
                }
            }
            .padding(AppSpacing.s16)
        }
        .skeleton(isActive: true)
        .scrollDisabled(true)
    }
}
