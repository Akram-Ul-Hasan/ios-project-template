import Observation

/// Groups a form's fields: overall validity for the submit button, submit-time validation,
/// and server field errors mapped back onto the inputs.
@MainActor
@Observable
public final class FormState {
    /// Name of the first invalid field after `validateAll()`, for moving focus there.
    public private(set) var firstInvalidField: String?

    @ObservationIgnored private let fields: [any FormValidatable]

    public init(_ fields: any FormValidatable...) {
        self.fields = fields
    }

    public var isValid: Bool {
        fields.allSatisfy(\.isValid)
    }

    /// Shows every field's error; returns `true` when the form can be submitted.
    @discardableResult
    public func validateAll() -> Bool {
        let results = fields.map { $0.validate() }
        firstInvalidField = zip(fields, results).first { !$0.1 }?.0.name
        return !results.contains(false)
    }

    /// Puts a 422's field errors under the matching inputs. Returns messages for fields this form doesn't have,
    /// so the caller can show them in a snackbar instead of dropping them.
    @discardableResult
    public func applyServerErrors(_ fieldErrors: [String: [String]]) -> [String] {
        var unmatched: [String] = []
        for (name, messages) in fieldErrors.sorted(by: { $0.key < $1.key }) {
            guard let message = messages.first else { continue }
            if let field = fields.first(where: { $0.name == name }) {
                field.setServerError(message)
            } else {
                unmatched.append(message)
            }
        }
        firstInvalidField = fields.first { !$0.isValid }?.name
        return unmatched
    }
}
