import Core
import Localization
import SharedDomain
import SwiftUI

extension EnvironmentValues {
    /// Set at the root from `LocalizationManager.formatters`, so prices follow the app language.
    @Entry public var appFormatters = AppFormatters(locale: .current)
}

/// The shared product tile for grids and carousels (any feature showing a `ProductEntity`).
public struct ProductCard: View {
    private let product: ProductEntity
    private let onTap: () -> Void
    private let onAddToCart: (() -> Void)?

    @Environment(\.appFormatters) private var formatters

    public init(product: ProductEntity, onTap: @escaping () -> Void, onAddToCart: (() -> Void)? = nil) {
        self.product = product
        self.onTap = onTap
        self.onAddToCart = onAddToCart
    }

    public var body: some View {
        TapArea(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.s8) {
                AppImage(url: product.imageURL, accessibilityLabel: product.name)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.r12))
                    .overlay(alignment: .topLeading) {
                        if product.status == .outOfStock { outOfStockLabel }
                    }
                Text(product.name)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2, reservesSpace: true)
                price
            }
            .padding(AppSpacing.s8)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.r16))
        }
        .overlay(alignment: .bottomTrailing) {
            if let onAddToCart, product.status == .active {
                AppIconButton(
                    systemImage: "plus.circle.fill", accessibilityLabel: L10n.Product.addToCart, action: onAddToCart
                )
                .foregroundStyle(AppColors.brandPrimary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var price: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s6) {
            Text(formatters.price(product.discountPrice ?? product.price))
                .font(AppTypography.bodyEmphasized)
                .foregroundStyle(AppColors.textPrimary)
            if product.discountPrice != nil {
                Text(formatters.price(product.price))
                    .font(AppTypography.caption)
                    .strikethrough()
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private var outOfStockLabel: some View {
        Text(L10n.Product.outOfStock)
            .font(AppTypography.captionEmphasized)
            .foregroundStyle(AppColors.onPrimary)
            .padding(.horizontal, AppSpacing.s8)
            .padding(.vertical, AppSpacing.s4)
            .background(AppColors.textSecondary, in: Capsule())
            .padding(AppSpacing.s8)
    }
}

#Preview {
    let product = ProductEntity(
        id: "1", name: "Miniket rice 5 kg, premium quality", price: 450, discountPrice: 399, imageURL: nil, tags: [],
        status: .active)
    let soldOut = ProductEntity(
        id: "2", name: "Mustard oil 1 L", price: 320, discountPrice: nil, imageURL: nil, tags: [], status: .outOfStock)
    LazyVGrid(columns: [GridItem(.adaptive(minimum: AppSize.gridItemMinWidth))], spacing: AppSpacing.s12) {
        ProductCard(product: product, onTap: {}, onAddToCart: {})
        ProductCard(product: soldOut, onTap: {}, onAddToCart: {})
        ProductCard(product: product, onTap: {}).skeleton(isActive: true)
    }
    .padding(AppSpacing.s16)
    .background(AppColors.background)
    .environment(\.appFormatters, AppFormatters(locale: Locale(identifier: "en_BD")))
}
