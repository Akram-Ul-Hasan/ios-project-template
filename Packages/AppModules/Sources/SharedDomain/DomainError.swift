/// Business-rule failures thrown by use cases. No user-facing text here:
/// Core's `ErrorMessages` maps each case to a localized message.
public enum DomainError: Error, Equatable, Sendable {
    /// `field` matches the form field / API field name, so the error lands under the right input.
    case validation(field: String, error: ValidationError)
    case outOfStock(productID: String)
    case subscriptionRequired
}
