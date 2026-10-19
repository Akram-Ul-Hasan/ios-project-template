import Foundation
import Testing

@testable import Core

@Suite("Endpoint")
struct EndpointTests {
    private struct Body: Encodable, Sendable {
        let phoneNumber: String
    }

    private struct Search: Endpoint {
        var path: String { "/v1/products" }
        var method: HTTPMethod { .get }
        var query: [URLQueryItem] { [URLQueryItem(name: "q", value: "rice & dal")] }
        var requiresAuth: Bool { false }
    }

    private struct Login: Endpoint {
        var path: String { "/v1/auth/login" }
        var method: HTTPMethod { .post }
        var body: (any Encodable & Sendable)? { Body(phoneNumber: "017") }
        var headers: [String: String] { ["X-Client": "ios"] }
    }

    private let baseURL = URL(string: "https://api.example.com")!

    @Test("GET builds path and encoded query, no body")
    func get() throws {
        let request = try Search().makeRequest(baseURL: baseURL, encoder: .app)
        #expect(request.url?.absoluteString == "https://api.example.com/v1/products?q=rice%20%26%20dal")
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
        #expect(!Search().requiresAuth)
    }

    @Test("POST encodes a snake_case JSON body and custom headers")
    func post() throws {
        let request = try Login().makeRequest(baseURL: baseURL, encoder: .app)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "X-Client") == "ios")
        #expect(String(decoding: request.httpBody ?? Data(), as: UTF8.self) == #"{"phone_number":"017"}"#)
        #expect(Login().requiresAuth)
    }
}
