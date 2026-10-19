import Foundation
import TestSupport
import Testing

@testable import Core

@Suite("SecureTokenStore")
struct SecureTokenStoreTests {
    @Test("Saves, reads and clears both tokens, keeping the encryption key")
    func roundTrip() throws {
        let keychain = InMemoryKeychain()
        let store = SecureTokenStore(keychain: keychain)
        #expect(store.tokens() == nil)

        let tokens = AuthTokens(accessToken: "a1", refreshToken: "r1")
        try store.save(tokens)
        try keychain.set(Data([1]), for: .encryptionKey)
        #expect(store.tokens() == tokens)

        try store.clear()
        #expect(store.tokens() == nil)
        #expect(try keychain.data(for: .encryptionKey) == Data([1]))
    }
}
