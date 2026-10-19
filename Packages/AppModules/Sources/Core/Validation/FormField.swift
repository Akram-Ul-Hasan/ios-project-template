import Observation
import SharedDomain

/// What `FormState` needs from any field, whatever its value type.
@MainActor
public protocol FormValidatable: AnyObject {
    /// The API field name, so server errors (`"phone": ["Taken"]`) land on the right input.
    var name: String { get }
    var isValid: Bool { get }
    @discardableResult func validate() -> Bool
    func setServerError(_ message: String?)
}

/// One input's state (§6o). Errors appear after the first blur (or submit), then update live while typing.
/// Rules are the shared `SharedDomain.Rules`, never ad-hoc regex (rule 35).
@MainActor
@Observable
public final class FormField<Value: Equatable & Sendable>: FormValidatable {
    public let name: String
    public var value: Value {
        didSet {
            guard value != oldValue else { return }
            serverError = nil
            if isTouched { runRules() }
        }
    }
    public private(set) var error: ValidationError?
    /// Message from a 422 response; cleared as soon as the user edits the field.
    public private(set) var serverError: String?
    public private(set) var isTouched = false

    @ObservationIgnored private let rules: @MainActor () -> [ValidationRule<Value>]

    public convenience init(name: String, _ value: Value, rules: [ValidationRule<Value>]) {
        self.init(name: name, value, dynamicRules: { rules })
    }

    /// Rules that depend on another field, e.g. confirm password:
    /// `FormField(name: "password_confirmation", "", dynamicRules: { [Rules.matches(password.value)] })`.
    public init(name: String, _ value: Value, dynamicRules: @escaping @MainActor () -> [ValidationRule<Value>]) {
        self.name = name
        self.value = value
        self.rules = dynamicRules
    }

    /// Localized text for the field's error label, or `nil` when there's nothing to show.
    public var errorMessage: String? {
        serverError ?? error?.localizedMessage
    }

    public var isValid: Bool {
        serverError == nil && ValidationRule.all(rules()).validate(value) == nil
    }

    /// Call when the field loses focus.
    public func onBlur() {
        isTouched = true
        runRules()
    }

    @discardableResult
    public func validate() -> Bool {
        isTouched = true
        runRules()
        return isValid
    }

    public func setServerError(_ message: String?) {
        serverError = message
        isTouched = true
    }

    public func reset(to value: Value) {
        self.value = value
        error = nil
        serverError = nil
        isTouched = false
    }

    private func runRules() {
        error = ValidationRule.all(rules()).validate(value)
    }
}
