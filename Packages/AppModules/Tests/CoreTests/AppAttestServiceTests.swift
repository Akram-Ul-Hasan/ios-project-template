import Foundation
import TestSupport
import Testing

@testable import Core

@Suite("AppAttestService")
struct AppAttestServiceTests {
    @Test("Unsupported environments (simulator, Mac) fail clearly instead of crashing")
    func unsupported() async throws {
        let service = AppAttestService(keychain: InMemoryKeychain())
        try #require(!service.isSupported)
        await #expect(throws: AppAttestError.unsupported) { try await service.attest(challenge: Data("c".utf8)) }
        await #expect(throws: AppAttestError.unsupported) { try await service.assertion(for: Data("body".utf8)) }
    }

    @Test("The client data hash is SHA-256 of the payload")
    func hash() {
        #expect(
            AppAttestService.hash(Data("abc".utf8)).base64EncodedString()
                == "ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=")
    }

    @Test("The App Attest key id survives logout")
    func survivesLogout() {
        #expect(!KeychainKey.sessionKeys.contains(.appAttestKeyID))
    }
}
