import Core
import SwiftUI

/// Swipeable promo banners with page dots and optional auto-advance (paused under Reduce Motion).
/// `BannerCarousel(banners, autoAdvance: .seconds(5)) { banner in AppImage(url: banner.imageURL) }`
public struct BannerCarousel<Item: Identifiable, Content: View>: View {
    private let items: [Item]
    private let autoAdvance: Duration?
    private let content: (Item) -> Content

    @State private var current: Item.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ items: [Item], autoAdvance: Duration? = nil, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.autoAdvance = autoAdvance
        self.content = content
    }

    public var body: some View {
        VStack(spacing: AppSpacing.s8) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(items) { item in
                        content(item)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.r16))
                            .padding(.horizontal, AppSpacing.s16)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $current)
            .scrollIndicators(.hidden)
            .frame(height: AppSize.bannerHeight)

            if items.count > 1 {
                HStack(spacing: AppSpacing.s6) {
                    ForEach(items) { item in
                        Circle()
                            .fill(item.id == (current ?? items.first?.id) ? AppColors.brandPrimary : AppColors.border)
                            .frame(width: AppSize.pageIndicatorDot, height: AppSize.pageIndicatorDot)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .task(id: autoAdvanceKey) { await runAutoAdvance() }
    }

    private var autoAdvanceKey: Bool { autoAdvance != nil && !reduceMotion && items.count > 1 }

    private func runAutoAdvance() async {
        guard autoAdvanceKey, let autoAdvance else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: autoAdvance)
            guard !Task.isCancelled else { return }
            let index = items.firstIndex { $0.id == current } ?? 0
            guard let next = items[safe: (index + 1) % items.count] else { return }
            withAnimation(AppAnimation.slow) { current = next.id }
        }
    }
}

#Preview {
    struct Banner: Identifiable {
        let id: Int
    }
    return BannerCarousel([Banner(id: 1), Banner(id: 2), Banner(id: 3)], autoAdvance: .seconds(3)) { banner in
        AppColors.brandPrimary.opacity(Double(banner.id) / 3)
    }
}
