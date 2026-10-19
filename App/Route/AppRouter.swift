import Core
import Observation
import os

/// The single source of navigation state (§6b): selected tab, one path per tab, the app-level sheet.
@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var paths: [AppTab: [Route]] = [:]
    var sheet: SheetRoute?

    /// Tapping the current tab again pops it to its root.
    func select(_ tab: AppTab) {
        if tab == selectedTab {
            popToRoot()
        } else {
            selectedTab = tab
        }
    }

    func push(_ route: Route) {
        AppLogger.navigation.debug("push \(String(describing: route), privacy: .private)")
        paths[selectedTab, default: []].append(route)
    }

    func pop() {
        _ = paths[selectedTab]?.popLast()
    }

    func popToRoot() {
        paths[selectedTab] = []
    }

    func present(_ sheet: SheetRoute) {
        self.sheet = sheet
    }

    func dismissSheet() {
        sheet = nil
    }

    /// Back to a clean slate, e.g. after logout.
    func reset() {
        selectedTab = .home
        paths = [:]
        sheet = nil
    }
}
