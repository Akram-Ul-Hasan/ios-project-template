import DesignSystem
import Localization
import SwiftUI

/// Stand-in until an onboarding feature exists.
struct OnboardingPlaceholder: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.s24) {
            Spacer()
            EmptyStateView(systemImage: "sparkles", title: L10n.Onboarding.title, message: L10n.Onboarding.message)
            Spacer()
            PrimaryButton(L10n.Onboarding.getStarted, action: onFinish)
        }
        .padding(AppSpacing.s24)
        .frame(maxWidth: AppSpacing.readableWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}
