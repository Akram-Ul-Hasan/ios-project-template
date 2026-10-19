import SwiftUI

/// The standard raised container: surface background, rounded corners, small shadow.
public struct AppCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    public init(padding: CGFloat = AppSpacing.s16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.r16))
            .appShadow(.small)
    }
}

#Preview {
    AppCard {
        VStack(alignment: .leading, spacing: AppSpacing.s8) {
            Text(verbatim: "Delivery address").font(AppTypography.headline)
            AppDivider()
            Text(verbatim: "House 12, Road 5, Dhanmondi").font(AppTypography.body)
        }
    }
    .padding(AppSpacing.s16)
    .background(AppColors.background)
}
