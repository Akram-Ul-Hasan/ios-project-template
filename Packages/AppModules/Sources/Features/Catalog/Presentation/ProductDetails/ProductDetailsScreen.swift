import CatalogDomain
import Core
import DesignSystem
import Localization
import SharedDomain
import SwiftUI

public struct ProductDetailsScreen: View {
    @State private var viewModel: ProductDetailsViewModel

    public init(viewModel: ProductDetailsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ViewStateContainer(
            state: viewModel.state, onRetry: { await viewModel.load() }, onRefresh: { await viewModel.refresh() }
        ) { details in
            ProductDetailsContent(details: details)
        }
        .background(AppColors.background)
        .commonAppBar(L10n.Route.productDetails)
        .task { await viewModel.load() }
    }
}

private struct ProductDetailsContent: View {
    let details: ProductDetailsEntity
    @Environment(\.appFormatters) private var formatters

    private struct GalleryImage: Identifiable {
        let id: URL
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.s16) {
                gallery
                VStack(alignment: .leading, spacing: AppSpacing.s8) {
                    Text(details.product.name)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s8) {
                        Text(formatters.price(details.product.discountPrice ?? details.product.price))
                            .font(AppTypography.title3)
                            .foregroundStyle(AppColors.textPrimary)
                        if details.product.discountPrice != nil {
                            Text(formatters.price(details.product.price))
                                .font(AppTypography.subheadline)
                                .strikethrough()
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    Label(
                        details.stock > 0 ? L10n.Catalog.inStock : L10n.Product.outOfStock,
                        systemImage: details.stock > 0 ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .font(AppTypography.subheadline)
                    .foregroundStyle(details.stock > 0 ? AppColors.success : AppColors.error)
                }
                VStack(alignment: .leading, spacing: AppSpacing.s8) {
                    SectionHeader(L10n.Catalog.description)
                    Text(details.description)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(AppSpacing.s16)
            .frame(maxWidth: AppSpacing.readableWidth)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var gallery: some View {
        let images = details.imageURLs.isEmpty ? [details.product.imageURL].compactMap { $0 } : details.imageURLs
        if images.count > 1 {
            BannerCarousel(images.map(GalleryImage.init)) { image in
                AppImage(url: image.id, accessibilityLabel: details.product.name)
            }
        } else {
            AppImage(url: images.first, accessibilityLabel: details.product.name)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.r16))
        }
    }
}
