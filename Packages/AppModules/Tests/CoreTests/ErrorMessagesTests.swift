import Localization
import SharedDomain
import Testing

@testable import Core

extension LanguageSensitive {
    @Suite("ErrorMessages")
    struct ErrorMessagesTests {
        init() { LocalizationBundle.apply(.en) }

        @Test("Server messages win for business and validation errors")
        func serverMessageWins() {
            #expect(ResponseError.business(code: .outOfStock, message: "Only 2 left").localizedMessage == "Only 2 left")
            #expect(ResponseError.validation(message: "Fix phone", fieldErrors: [:]).localizedMessage == "Fix phone")
        }

        @Test("Without a server message the local one is used")
        func localFallback() {
            #expect(
                ResponseError.business(code: .outOfStock, message: nil).localizedMessage == "This item is out of stock."
            )
            #expect(ResponseError.business(code: nil, message: "").localizedMessage == "Please try again.")
            #expect(ResponseError.validation(message: nil, fieldErrors: [:]).localizedMessage == L10n.Error.validation)
        }

        @Test("Validation messages carry their parameters, with plurals")
        func validationParameters() {
            #expect(ValidationError.tooShort(min: 8).localizedMessage == "At least 8 characters")
            #expect(ValidationError.tooShort(min: 1).localizedMessage == "At least 1 character")
            #expect(ValidationError.invalidFormat(.otp).localizedMessage == "Enter the 6-digit code.")
            #expect(
                ResponseError.domain(.validation(field: "phone", error: .required)).localizedMessage
                    == L10n.Validation.required)
        }

        @Test("Messages follow the active language")
        func bangla() {
            defer { LocalizationBundle.apply(.en) }
            LocalizationBundle.apply(.bn)
            #expect(ResponseError.network.localizedMessage == "ইন্টারনেট সংযোগ নেই। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।")
        }
    }
}
