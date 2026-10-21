import DesignSystem
import Localization
import SwiftUI

/// Stand-in for a tab's root screen until its feature exists. The buttons exercise navigation.
struct TabRootPlaceholder: View {
    let tab: AppTab
    let router: AppRouter

    var body: some View {
        VStack(spacing: AppSpacing.s16) {
            EmptyStateView(systemImage: tab.systemImage, title: tab.title, message: L10n.Placeholder.message)
            switch tab {
            case .categories:
                SecondaryButton(L10n.Sheet.filter) { router.present(.filter) }
            case .account:
                SecondaryButton(L10n.Route.orders) { router.push(.orders) }
                SecondaryButton(L10n.Route.settings) { router.push(.settings) }
            case .home, .cart:
                EmptyView()
            }
        }
        .padding(AppSpacing.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .commonAppBar(tab.title, showsBack: false)
    }
}
