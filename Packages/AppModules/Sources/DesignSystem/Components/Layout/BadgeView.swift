import SwiftUI

/// A count bubble (cart items, unread notifications). Hidden for `nil` or 0; shows "99+" above 99.
/// Digits follow the app language through the environment locale.
public struct BadgeView: View {
    private let count: Int?

    public init(count: Int?) {
        self.count = count
    }

    public var body: some View {
        if let display = Self.display(count) {
            Group {
                if display.overflow {
                    Text(display.value, format: .number) + Text(verbatim: "+")
                } else {
                    Text(display.value, format: .number)
                }
            }
            .font(AppTypography.captionEmphasized)
            .foregroundStyle(AppColors.onPrimary)
            .padding(.horizontal, AppSpacing.s4)
            .frame(minWidth: AppSize.badgeMinSize, minHeight: AppSize.badgeMinSize)
            .background(AppColors.error, in: Capsule())
            .fixedSize()
            .accessibilityHidden(true)
        }
    }

    static func display(_ count: Int?) -> (value: Int, overflow: Bool)? {
        guard let count, count > 0 else { return nil }
        return count > maxShown ? (maxShown, true) : (count, false)
    }

    private static let maxShown = 99
}

#Preview {
    HStack(spacing: AppSpacing.s16) {
        BadgeView(count: 3)
        BadgeView(count: 42)
        BadgeView(count: 250)
        BadgeView(count: 0)
    }
}
