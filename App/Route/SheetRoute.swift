/// App-level sheets: openable from anywhere, including deep links. Screen-local sheets stay in the screen's state.
enum SheetRoute: String, Identifiable, Hashable {
    case filter
    case deliveryArea

    var id: Self { self }
}
