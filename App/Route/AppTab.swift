import Localization

/// The tabs, in display order. Each keeps its own navigation history (§6b).
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case categories
    case cart
    case account

    var id: Self { self }

    var title: String {
        switch self {
        case .home: L10n.Tab.home
        case .categories: L10n.Tab.categories
        case .cart: L10n.Tab.cart
        case .account: L10n.Tab.account
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .categories: "square.grid.2x2"
        case .cart: "cart"
        case .account: "person"
        }
    }
}
