import CryptoKit
import Foundation

/// Encrypts sensitive data that is too large for the Keychain (§6i).
public protocol EncryptionManager: Sendable {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ data: Data) throws -> Data
}

public enum EncryptionError: Error, Equatable, Sendable {
    case sealFailed
}

/// AES-256-GCM (authenticated: tampered data fails to decrypt). The key is created once and kept in the Keychain.
public final class AESGCMEncryptionManager: EncryptionManager {
    private let key: SymmetricKey

    public init(keychain: any KeychainStoring) throws {
        if let stored = try keychain.data(for: .encryptionKey) {
            key = SymmetricKey(data: stored)
        } else {
            let key = SymmetricKey(size: .bits256)
            try keychain.set(key.withUnsafeBytes { Data($0) }, for: .encryptionKey)
            self.key = key
        }
    }

    public func encrypt(_ data: Data) throws -> Data {
        guard let sealed = try AES.GCM.seal(data, using: key).combined else { throw EncryptionError.sealFailed }
        return sealed
    }

    public func decrypt(_ data: Data) throws -> Data {
        try AES.GCM.open(AES.GCM.SealedBox(combined: data), using: key)
    }
}
