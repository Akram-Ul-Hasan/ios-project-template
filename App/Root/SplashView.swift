import DesignSystem
import SwiftUI

/// Shown while `AppContainer.bootstrap()` runs. Matches the launch screen so the hand-off is seamless.
struct SplashView: View {
    var body: some View {
        VStack(spacing: AppSpacing.s24) {
            Image(systemName: "bag.fill")
                .font(.system(size: AppIconSize.illustration))
                .foregroundStyle(AppColors.brandPrimary)
                .accessibilityHidden(true)
            ProgressView()
                .tint(AppColors.brandPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}
