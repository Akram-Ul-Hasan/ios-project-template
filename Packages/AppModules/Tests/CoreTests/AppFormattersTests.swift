import Foundation
import Testing

@testable import Core

@Suite("AppFormatters")
struct AppFormattersTests {
    private let english = AppFormatters(locale: Locale(identifier: "en_BD"), timeZone: TimeZone(identifier: "UTC")!)
    private let bangla = AppFormatters(
        locale: Locale(identifier: "bn_BD@numbers=beng"), timeZone: TimeZone(identifier: "UTC")!)
    private let date = Date(timeIntervalSince1970: 1_792_404_000)

    @Test("Prices use the taka sign, South Asian grouping and Bangla digits in Bangla")
    func prices() {
        #expect(english.price(1250) == "৳1,250")
        #expect(english.price(Decimal(string: "1250.5")!) == "৳1,250.5")
        #expect(english.price(150_000) == "৳1,50,000")
        #expect(bangla.price(1250) == "৳১,২৫০")
    }

    @Test("Numbers, dates and relative times follow the locale")
    func others() {
        #expect(bangla.number(42) == "৪২")
        #expect(english.date(date) == "19 Oct, 2026")
        #expect(bangla.date(date) == "১৯ অক্টো, ২০২৬")
        #expect(english.relative(date, to: date.addingTimeInterval(7200)) == "2 hours ago")
    }
}
