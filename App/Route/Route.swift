/// Every pushed screen. Features don't see this enum: their screens expose callbacks
/// (`onProductTap: (String) -> Void`) and `RouteView` turns them into routes (§6b).
enum Route: Hashable {
    case productDetails(id: String)
    case orders
    case orderDetails(id: String)
    case settings
}
