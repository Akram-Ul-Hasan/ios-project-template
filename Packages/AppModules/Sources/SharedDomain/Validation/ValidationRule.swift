/// A pure check: returns the first problem with a value, or `nil` when it's valid.
/// The same rules run in the UI (`FormField`), in use cases (`DomainError.validation`) and nowhere else (rule 35).
public struct ValidationRule<Value>: Sendable {
    private let check: @Sendable (Value) -> ValidationError?

    public init(_ check: @escaping @Sendable (Value) -> ValidationError?) {
        self.check = check
    }

    public func validate(_ value: Value) -> ValidationError? {
        check(value)
    }

    /// Runs `rules` in order and reports the first failure.
    public static func all(_ rules: [ValidationRule<Value>]) -> ValidationRule<Value> {
        ValidationRule { value in
            for rule in rules {
                if let error = rule.validate(value) { return error }
            }
            return nil
        }
    }
}
