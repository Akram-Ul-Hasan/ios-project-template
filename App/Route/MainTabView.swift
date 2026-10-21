import CatalogPresentation
import DesignSystem
import SwiftUI

/// The signed-in shell: native tab bar, one `NavigationStack` per tab so each keeps its history (§6b).
/// For a custom Figma bar, hide this one with `.toolbar(.hidden, for: .tabBar)` and overlay `AppTabBar`.
struct MainTabView: View {
    let container: AppContainer
    @Bindable var router: AppRouter

    var body: some View {
        TabView(selection: selection) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack(path: path(for: tab)) {
                    root(for: tab)
                        .navigationDestination(for: Route.self) { RouteView(route: $0, container: container) }
                }
                .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                .tag(tab)
            }
        }
        .tint(AppColors.brandPrimary)
        .appSheet(item: $router.sheet) { SheetRouteView(sheet: $0, router: router) }
    }

    /// Each tab's first screen. Tabs without a feature yet show a placeholder.
    @ViewBuilder
    private func root(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            ProductListScreen(
                viewModel: container.catalog.makeProductListViewModel { router.push(.productDetails(id: $0)) })
        case .categories, .cart, .account:
            TabRootPlaceholder(tab: tab, router: router)
        }
    }

    /// SwiftUI calls the setter even when the current tab is tapped again, which `select` turns into pop-to-root.
    private var selection: Binding<AppTab> {
        Binding(get: { router.selectedTab }, set: { router.select($0) })
    }

    private func path(for tab: AppTab) -> Binding<[Route]> {
        Binding(get: { router.paths[tab, default: []] }, set: { router.paths[tab] = $0 })
    }
}
