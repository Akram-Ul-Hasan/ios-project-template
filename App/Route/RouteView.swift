import DesignSystem
import Localization
import SwiftUI

/// The only place that maps routes to screens. Feature screens get their view models from the containers
/// and their navigation as callbacks wired to the router here, so features never see `Route` (§6b).
struct RouteView: View {
    let route: Route
    let container: AppContainer

    var body: some View {
        switch route {
        case .productDetails(let id):
            RoutePlaceholder(title: L10n.Route.productDetails, detail: id)
        case .orders:
            RoutePlaceholder(title: L10n.Route.orders, detail: nil)
        case .orderDetails(let id):
            RoutePlaceholder(title: L10n.Route.orderDetails, detail: id)
        case .settings:
            RoutePlaceholder(title: L10n.Route.settings, detail: nil)
        }
    }
}

/// App-level sheets presented by `AppRouter.sheet`.
struct SheetRouteView: View {
    let sheet: SheetRoute
    let router: AppRouter

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s16) {
            SheetHeader(title, onClose: router.dismissSheet)
            Text(L10n.Placeholder.message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.s16)
                .padding(.bottom, AppSpacing.s24)
        }
    }

    private var title: String {
        switch sheet {
        case .filter: L10n.Sheet.filter
        case .deliveryArea: L10n.Sheet.deliveryArea
        }
    }
}

/// Stand-in for a pushed screen until its feature exists.
private struct RoutePlaceholder: View {
    let title: String
    let detail: String?

    var body: some View {
        EmptyStateView(
            systemImage: "hammer", title: title,
            message: [detail, L10n.Placeholder.message].compactMap { $0 }.joined(separator: "\n")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .commonAppBar(title)
    }
}
