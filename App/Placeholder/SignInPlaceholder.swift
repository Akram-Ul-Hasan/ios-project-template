import Core
import DesignSystem
import Localization
import SwiftUI

/// Stand-in until the auth feature's login screen is wired in. Debug builds can skip with a fake session.
struct SignInPlaceholder: View {
    let tokenStore: any TokenStore
    let onSignedIn: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.s24) {
            EmptyStateView(systemImage: "person.badge.key", title: L10n.SignIn.title, message: L10n.Placeholder.message)
            #if DEBUG
                SecondaryButton(L10n.SignIn.skip) {
                    try? tokenStore.save(AuthTokens(accessToken: "debug-access", refreshToken: "debug-refresh"))
                    onSignedIn()
                }
            #endif
        }
        .padding(AppSpacing.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}
