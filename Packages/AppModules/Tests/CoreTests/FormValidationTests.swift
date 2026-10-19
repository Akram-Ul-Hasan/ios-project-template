import Localization
import SharedDomain
import Testing

@testable import Core

extension LanguageSensitive {
    @Suite("Form validation")
    @MainActor
    struct FormValidationTests {
        init() { LocalizationBundle.apply(.en) }

        private func phone() -> FormField<String> {
            FormField(name: "phone", "", rules: [Rules.required, Rules.phoneBD])
        }

        @Test("No error before the first blur; live updates after it")
        func touchFlow() {
            let field = phone()
            field.value = "017"
            #expect(field.errorMessage == nil)
            field.onBlur()
            #expect(field.error == .invalidFormat(.phone))
            #expect(field.errorMessage == "Enter a valid phone number.")
            field.value = "01712345678"
            #expect(field.error == nil && field.isValid)
        }

        @Test("A server error shows until the user edits the field")
        func serverError() {
            let field = phone()
            field.value = "01712345678"
            field.setServerError("Already registered")
            #expect(field.errorMessage == "Already registered" && !field.isValid)
            field.value = "01812345678"
            #expect(field.serverError == nil && field.isValid)
        }

        @Test("Dynamic rules see the other field's current value")
        func confirmPassword() {
            let password = FormField(name: "password", "abcd1234", rules: [Rules.password])
            let confirm = FormField(
                name: "password_confirmation", "abcd1234", dynamicRules: { [Rules.matches(password.value)] })
            #expect(confirm.validate())
            password.value = "zzzz9999"
            #expect(!confirm.validate())
            #expect(confirm.error == .mismatch)
        }

        @Test("validateAll shows every error and reports the first invalid field")
        func validateAll() {
            let name = FormField(name: "name", "", rules: [Rules.required])
            let phone = phone()
            let form = FormState(name, phone)
            #expect(!form.isValid)
            #expect(!form.validateAll())
            #expect(form.firstInvalidField == "name")
            #expect(name.error == .required && phone.error == .required)

            name.value = "Rahim"
            phone.value = "01712345678"
            #expect(form.validateAll() && form.isValid && form.firstInvalidField == nil)
        }

        @Test("Server errors land on matching fields; the rest are returned")
        func serverErrors() {
            let phone = phone()
            phone.value = "01712345678"
            let form = FormState(phone)
            let unmatched = form.applyServerErrors(["phone": ["Taken"], "device_id": ["Blocked"], "empty": []])
            #expect(phone.errorMessage == "Taken")
            #expect(unmatched == ["Blocked"])
            #expect(form.firstInvalidField == "phone")
        }

        @Test("reset clears value, errors and touched state")
        func reset() {
            let field = phone()
            field.validate()
            field.reset(to: "")
            #expect(field.error == nil && !field.isTouched && field.errorMessage == nil)
        }
    }
}
