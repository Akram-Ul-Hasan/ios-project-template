import DesignSystem
import Localization
import SwiftUI
import __Feature__Domain

/// One adaptive layout from the portrait design (§2a). Check it in `PreviewMatrix` before review.
public struct __Feature__ListScreen: View {
    @State private var viewModel: __Feature__ListViewModel

    public init(viewModel: __Feature__ListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        PaginatedList(viewModel.items, onRefresh: { await viewModel.refresh() }) { item in
            TapArea {
                viewModel.select(item)
            } label: {
                AppCard {
                    Text(item.title)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
        .background(AppColors.background)
        .commonAppBar(L10n.__Feature__.title)
    }
}
