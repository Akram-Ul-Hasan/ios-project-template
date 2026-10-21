import Foundation
import Testing

@testable import Core

@Suite("Env")
struct EnvTests {
    @Test("Reads environment and base URL from Info.plist values")
    func valid() throws {
        let env = try Env(infoDictionary: ["APP_ENV": "staging", "BASE_URL": "https://api-stg.example.com"])
        #expect(env.environment == .staging)
        #expect(env.baseURL.absoluteString == "https://api-stg.example.com")
        #expect(env.isDiagnosticsEnabled)
    }

    @Test("Pins are optional and split on spaces or commas")
    func pins() throws {
        let none = try Env(infoDictionary: ["APP_ENV": "development", "BASE_URL": "https://x.com"])
        #expect(none.pinnedKeyHashes.isEmpty)
        let two = try Env(infoDictionary: [
            "APP_ENV": "production", "BASE_URL": "https://x.com", "PINNED_PUBLIC_KEY_HASHES": "aaa=, bbb=",
        ])
        #expect(two.pinnedKeyHashes == ["aaa=", "bbb="])
    }

    @Test("Production disables diagnostics")
    func production() throws {
        let env = try Env(infoDictionary: ["APP_ENV": "production", "BASE_URL": "https://api.example.com"])
        #expect(!env.isDiagnosticsEnabled)
    }

    @Test(
        "Broken configuration throws",
        arguments: [
            ([:], EnvError.missing("APP_ENV")),
            (["APP_ENV": "qa", "BASE_URL": "https://x.com"], .invalid("APP_ENV", "qa")),
            (["APP_ENV": "staging"], .missing("BASE_URL")),
            (["APP_ENV": "staging", "BASE_URL": "http://x.com"], .invalid("BASE_URL", "http://x.com")),
            (["APP_ENV": "staging", "BASE_URL": "$(BASE_URL)"], .invalid("BASE_URL", "$(BASE_URL)")),
        ])
    func invalid(info: [String: String], expected: EnvError) {
        #expect(throws: expected) { try Env(infoDictionary: info) }
    }
}
