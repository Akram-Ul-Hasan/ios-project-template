import Testing

@testable import SharedDomain

@Suite("Validation rules")
struct RulesTests {
    @Test("required", arguments: [("", ValidationError.required), ("   \n", .required), ("a", nil)])
    func required(value: String, expected: ValidationError?) {
        #expect(Rules.required.validate(value) == expected)
    }

    @Test("selection requires a value")
    func selection() {
        let rule: ValidationRule<Int?> = Rules.selection()
        #expect(rule.validate(nil) == .required)
        #expect(rule.validate(3) == nil)
    }

    @Test("minLength / maxLength")
    func lengths() {
        #expect(Rules.minLength(3).validate("ab") == .tooShort(min: 3))
        #expect(Rules.minLength(3).validate("abc") == nil)
        #expect(Rules.maxLength(3).validate("abcd") == .tooLong(max: 3))
        #expect(Rules.maxLength(3).validate("abc") == nil)
    }

    @Test("phoneBD accepts BD mobile numbers", arguments: ["01712345678", "+8801712345678", "8801912345678"])
    func phoneValid(value: String) {
        #expect(Rules.phoneBD.validate(value) == nil)
    }

    @Test(
        "phoneBD rejects everything else", arguments: ["0171234567", "01212345678", "017123456789", "0171234567a", ""])
    func phoneInvalid(value: String) {
        #expect(Rules.phoneBD.validate(value) == .invalidFormat(.phone))
    }

    @Test("email")
    func email() {
        #expect(Rules.email.validate("name.surname+tag@example.com.bd") == nil)
        #expect(Rules.email.validate("name@example") == .invalidFormat(.email))
        #expect(Rules.email.validate("@example.com") == .invalidFormat(.email))
    }

    @Test(
        "otp",
        arguments: [
            ("123456", nil), ("12345", ValidationError.invalidFormat(.otp)), ("12345a", .invalidFormat(.otp)),
            ("১২৩৪৫৬", .invalidFormat(.otp)),
        ])
    func otp(value: String, expected: ValidationError?) {
        #expect(Rules.otp.validate(value) == expected)
    }

    @Test(
        "password",
        arguments: [
            ("abc12", ValidationError.tooShort(min: 8)), ("abcdefgh", .invalidFormat(.password)),
            ("12345678", .invalidFormat(.password)), ("abcd1234", nil),
        ])
    func password(value: String, expected: ValidationError?) {
        #expect(Rules.password.validate(value) == expected)
    }

    @Test("matches")
    func matches() {
        #expect(Rules.matches("secret1").validate("secret1") == nil)
        #expect(Rules.matches("secret1").validate("secret2") == .mismatch)
    }

    @Test("range")
    func range() {
        #expect(Rules.range(1...10).validate(0) == .outOfRange)
        #expect(Rules.range(1...10).validate(10) == nil)
    }

    @Test("all reports the first failing rule, in order")
    func all() {
        let rule = ValidationRule.all([Rules.required, Rules.phoneBD])
        #expect(rule.validate("") == .required)
        #expect(rule.validate("123") == .invalidFormat(.phone))
        #expect(rule.validate("01712345678") == nil)
    }
}
