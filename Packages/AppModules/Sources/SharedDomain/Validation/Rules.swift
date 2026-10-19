/// The app's validation rules. Views and view models never write their own regex (rule 35).
public enum Rules {
    public static let required = ValidationRule<String> {
        $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .required : nil
    }

    /// Pickers and dropdowns: something must be selected.
    public static func selection<Value: Sendable>() -> ValidationRule<Value?> {
        ValidationRule { $0 == nil ? .required : nil }
    }

    public static func minLength(_ min: Int) -> ValidationRule<String> {
        ValidationRule { $0.count < min ? .tooShort(min: min) : nil }
    }

    public static func maxLength(_ max: Int) -> ValidationRule<String> {
        ValidationRule { $0.count > max ? .tooLong(max: max) : nil }
    }

    public static let phoneBD = ValidationRule<String> {
        $0.wholeMatch(of: ValidationConstants.phoneBD) == nil ? .invalidFormat(.phone) : nil
    }

    public static let email = ValidationRule<String> {
        $0.wholeMatch(of: ValidationConstants.email) == nil ? .invalidFormat(.email) : nil
    }

    public static let otp = ValidationRule<String> {
        $0.count == ValidationConstants.otpLength && $0.allSatisfy(\.isASCIIDigit) ? nil : .invalidFormat(.otp)
    }

    /// At least `passwordMin` characters, with at least one letter and one digit.
    public static let password = ValidationRule<String> { value in
        if value.count < ValidationConstants.passwordMin { return .tooShort(min: ValidationConstants.passwordMin) }
        let hasLetter = value.contains(where: \.isLetter)
        let hasDigit = value.contains(where: \.isASCIIDigit)
        return hasLetter && hasDigit ? nil : .invalidFormat(.password)
    }

    /// Confirmation fields: build it with the current value of the field being confirmed.
    public static func matches(_ expected: String) -> ValidationRule<String> {
        ValidationRule { $0 == expected ? nil : .mismatch }
    }

    public static func range<Value: Comparable & Sendable>(_ range: ClosedRange<Value>) -> ValidationRule<Value> {
        ValidationRule { range.contains($0) ? nil : .outOfRange }
    }
}

extension Character {
    fileprivate var isASCIIDigit: Bool { isASCII && isNumber }
}
