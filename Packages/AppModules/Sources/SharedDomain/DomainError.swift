/// Business-rule failures thrown by use cases. No user-facing text here:
/// Core's `ErrorMessages` maps each case to a localized message.
public enum DomainError: Error, Equatable, Sendable {
    case outOfStock(productID: String)
    case subscriptionRequired
}
