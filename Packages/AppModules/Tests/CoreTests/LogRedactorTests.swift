import Testing

@testable import Core

@Suite("LogRedactor")
struct LogRedactorTests {
    @Test(
        "Secrets are redacted",
        arguments: [
            (#"{"phone":"01712345678","password":"hunter2"}"#, #"{"phone":"01712345678","password":"<redacted>"}"#),
            (#"{"OTP" : "123456"}"#, #"{"OTP" : "<redacted>"}"#),
            (#"{"access_token":"abc.def","x":1}"#, #"{"access_token":"<redacted>","x":1}"#),
            ("Authorization: Bearer abc123.def-456", "Authorization: Bearer <redacted>"),
            ("token eyJhbGciOi.eyJzdWIiOi.SflKxwRJ end", "token <redacted> end"),
            ("/login?phone=017&password=x&otp=1234", "/login?phone=017&password=<redacted>&otp=<redacted>"),
            ("card 4111 1111 1111 1111 ok", "card <redacted> ok"),
        ])
    func redacts(input: String, expected: String) {
        #expect(LogRedactor.redact(input) == expected)
    }

    @Test("Ordinary text is untouched")
    func untouched() {
        let text = "GET /products?page=2 → 200, phone 01712345678"
        #expect(LogRedactor.redact(text) == text)
    }
}
