/// Every place the app can be opened to from outside (§6c). A link only navigates: it never performs an action,
/// and the target screen re-checks what it needs (§6l).
enum DeepLink: Equatable {
    case product(id: String)
    case cart
    case orders
    case order(id: String)
    case settings

    var tab: AppTab {
        switch self {
        case .product: .home
        case .cart: .cart
        case .orders, .order, .settings: .account
        }
    }

    /// The full stack, so Back behaves as if the user navigated there.
    var routes: [Route] {
        switch self {
        case .product(let id): [.productDetails(id: id)]
        case .cart: []
        case .orders: [.orders]
        case .order(let id): [.orders, .orderDetails(id: id)]
        case .settings: [.settings]
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .product, .cart: false
        case .orders, .order, .settings: true
        }
    }
}
