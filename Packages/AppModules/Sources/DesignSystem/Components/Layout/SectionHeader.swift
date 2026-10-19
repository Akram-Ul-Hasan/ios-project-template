import Localization
import SwiftUI

/// A section title with an optional "See all" action.
public struct SectionHeader: View {
    private let title: String
    private let actionTitle: String
    private let action: (() -> Void)?

    public init(_ title: String, actionTitle: String = L10n.Section.seeAll, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let action {
                AppTextButton(actionTitle, action: action)
            }
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.s16) {
        SectionHeader("Popular now") {}
        SectionHeader("Recently viewed")
    }
    .padding(AppSpacing.s16)
}
