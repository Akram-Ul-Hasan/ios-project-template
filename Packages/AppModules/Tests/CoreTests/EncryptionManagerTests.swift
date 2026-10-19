import Foundation
import TestSupport
import Testing

@testable import Core

@Suite("AESGCMEncryptionManager")
struct EncryptionManagerTests {
    @Test("Round-trips and never stores plaintext")
    func roundTrip() throws {
        let manager = try AESGCMEncryptionManager(keychain: InMemoryKeychain())
        let plain = Data("card ending 4242".utf8)
        let sealed = try manager.encrypt(plain)
        #expect(sealed != plain)
        #expect(sealed.range(of: plain) == nil)
        #expect(try manager.decrypt(sealed) == plain)
    }

    @Test("The key persists across instances via the Keychain")
    func keyPersists() throws {
        let keychain = InMemoryKeychain()
        let sealed = try AESGCMEncryptionManager(keychain: keychain).encrypt(Data("x".utf8))
        #expect(try AESGCMEncryptionManager(keychain: keychain).decrypt(sealed) == Data("x".utf8))
    }

    @Test("Tampered data or a different key fails to decrypt")
    func tamper() throws {
        let manager = try AESGCMEncryptionManager(keychain: InMemoryKeychain())
        var sealed = try manager.encrypt(Data("secret".utf8))
        sealed[sealed.count - 1] ^= 0xFF
        #expect(throws: (any Error).self) { try manager.decrypt(sealed) }

        let other = try AESGCMEncryptionManager(keychain: InMemoryKeychain())
        #expect(throws: (any Error).self) { try other.decrypt(try manager.encrypt(Data("secret".utf8))) }
    }
}
