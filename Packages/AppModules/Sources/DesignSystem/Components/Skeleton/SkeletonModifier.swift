import Localization
import SwiftUI

extension View {
    /// Shows the view's own layout as grey placeholder blocks with a shimmer while loading:
    /// `ProductCard(product: .placeholder).skeleton(isActive: true)`.
    public func skeleton(isActive: Bool) -> some View {
        modifier(SkeletonModifier(isActive: isActive))
    }
}

struct SkeletonModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content
                .redacted(reason: .placeholder)
                .foregroundStyle(AppColors.skeleton)
                .overlay { Shimmer().mask(content.redacted(reason: .placeholder)) }
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.State.loading)
        } else {
            content
        }
    }
}

/// A light band sweeping across. Off when the user asked for reduced motion.
private struct Shimmer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            GeometryReader { proxy in
                LinearGradient(
                    colors: [.clear, .white.opacity(AppOpacity.secondary), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: proxy.size.width)
                .offset(x: phase * proxy.size.width)
            }
            .onAppear {
                withAnimation(.linear(duration: AppAnimation.shimmerDuration).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: AppSpacing.s8) {
        RoundedRectangle(cornerRadius: AppRadius.r12).frame(height: AppSize.bannerHeight)
        Text(verbatim: "Product name that is long")
            .font(AppTypography.headline)
        Text(verbatim: "৳1,250")
            .font(AppTypography.body)
    }
    .padding(AppSpacing.s16)
    .skeleton(isActive: true)
}
