import Foundation
import Testing

@testable import Core

@Suite("Decoding")
struct DecodingTests {
    private struct Order: Decodable, Equatable {
        let orderId: String
        let placedAt: Date
    }

    private struct Carousel: Decodable {
        @LossyArray var items: [Item]
    }

    private struct Item: Decodable, Equatable {
        let id: Int
    }

    private enum Status: UnknownCase, Equatable {
        case active
        case unknown(String)

        init(rawValue: String) { self = rawValue == "active" ? .active : .unknown(rawValue) }
        var rawValue: String {
            switch self {
            case .active: "active"
            case .unknown(let raw): raw
            }
        }
    }

    @Test(
        "Snake case keys and ISO-8601 dates with or without fractions",
        arguments: ["2026-10-19T10:00:00Z", "2026-10-19T10:00:00.000Z"])
    func dates(text: String) throws {
        let json = Data(#"{"order_id":"A1","placed_at":"\#(text)"}"#.utf8)
        let order = try JSONDecoder.app.decode(Order.self, from: json)
        #expect(order.orderId == "A1")
        #expect(order.placedAt == Date(timeIntervalSince1970: 1_792_404_000))
    }

    @Test("A malformed date fails decoding")
    func badDate() {
        let json = Data(#"{"order_id":"A1","placed_at":"19/10/2026"}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder.app.decode(Order.self, from: json) }
    }

    @Test("LossyArray keeps valid items and skips invalid ones")
    func lossy() throws {
        let json = Data(#"{"items":[{"id":1},{"id":"x"},{},{"id":4}]}"#.utf8)
        let carousel = try JSONDecoder.app.decode(Carousel.self, from: json)
        #expect(carousel.items == [Item(id: 1), Item(id: 4)])
    }

    @Test("Unknown enum values decode to .unknown and round-trip")
    func unknownCase() throws {
        let statuses = try JSONDecoder.app.decode([Status].self, from: Data(#"["active","archived"]"#.utf8))
        #expect(statuses == [.active, .unknown("archived")])
        #expect(String(decoding: try JSONEncoder.app.encode(statuses), as: UTF8.self) == #"["active","archived"]"#)
        #expect(try JSONDecoder.app.decode(BackendErrorCode.self, from: Data(#""OUT_OF_STOCK""#.utf8)) == .outOfStock)
    }
}
