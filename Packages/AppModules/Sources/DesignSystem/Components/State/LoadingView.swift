import Localization
import SwiftUI

/// Centered spinner for loads where a skeleton doesn't fit (first launch, a detail screen with no layout yet).
public struct LoadingView: View {
    private let message: String?

    public init(message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: AppSpacing.s12) {
            ProgressView()
                .tint(AppColors.brandPrimary)
            if let message {
                Text(message)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? L10n.State.loading)
    }
}

#Preview {
    LoadingView()
}
