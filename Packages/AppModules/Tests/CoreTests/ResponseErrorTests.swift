import Foundation
import SharedDomain
import Testing

@testable import Core

@Suite("ResponseError")
struct ResponseErrorTests {
    @Test(
        "Status codes map to the taxonomy",
        arguments: [
            (401, nil, ResponseError.unauthorized),
            (403, nil, .forbidden),
            (404, nil, .notFound),
            (
                409, BackendError(code: .outOfStock, message: "Gone", errors: nil),
                .business(code: .outOfStock, message: "Gone")
            ),
            (
                422, BackendError(code: nil, message: "Bad", errors: ["phone": ["Invalid"]]),
                .validation(message: "Bad", fieldErrors: ["phone": ["Invalid"]])
            ),
            (
                400, BackendError(code: nil, message: nil, errors: ["otp": ["Wrong"]]),
                .validation(message: nil, fieldErrors: ["otp": ["Wrong"]])
            ),
            (
                400, BackendError(code: .couponExpired, message: nil, errors: nil),
                .business(code: .couponExpired, message: nil)
            ),
            (400, nil, .unknown),
            (426, nil, .updateRequired),
            (503, nil, .maintenance),
            (500, nil, .server(statusCode: 500)),
        ] as [(Int, BackendError?, ResponseError)])
    func statusCodes(status: Int, body: BackendError?, expected: ResponseError) {
        #expect(ResponseError.from(statusCode: status, body: body) == expected)
    }

    @Test(
        "Transport errors",
        arguments: [
            (URLError(.notConnectedToInternet), ResponseError.network),
            (URLError(.networkConnectionLost), .network),
            (URLError(.timedOut), .timeout),
            (URLError(.cancelled), .cancelled),
            (URLError(.badServerResponse), .unknown),
        ])
    func transport(error: URLError, expected: ResponseError) {
        #expect(ResponseError.from(error) == expected)
    }

    @Test("Cancellation, domain errors and existing ResponseErrors pass through")
    func passThrough() {
        #expect(ResponseError.from(CancellationError()) == .cancelled)
        #expect(ResponseError.from(DomainError.subscriptionRequired) == .domain(.subscriptionRequired))
        #expect(ResponseError.from(ResponseError.forbidden) == .forbidden)
    }

    @Test("Decoding errors become invalidResponse with the key path and no values")
    func decoding() {
        struct Product: Decodable {
            let id: String
            let stock: Int
        }
        let missing = Result { try JSONDecoder().decode(Product.self, from: Data(#"{"id":"1"}"#.utf8)) }
        let mismatch = Result {
            try JSONDecoder().decode([Product].self, from: Data(#"[{"id":"secret","stock":"x"}]"#.utf8))
        }
        #expect(missing.responseError == .invalidResponse(detail: "missing key stock"))
        #expect(mismatch.responseError == .invalidResponse(detail: "expected Int at [0].stock"))
    }

    @Test("Unknown backend codes are kept, not dropped")
    func unknownCode() throws {
        let body = try JSONDecoder().decode(BackendError.self, from: Data(#"{"code":"NEW_THING"}"#.utf8))
        #expect(body.code == .unknown("NEW_THING"))
        #expect(BackendErrorCode(rawValue: "OUT_OF_STOCK") == .outOfStock)
    }
}

extension Result {
    fileprivate var responseError: ResponseError? {
        guard case .failure(let error) = self else { return nil }
        return ResponseError.from(error)
    }
}
