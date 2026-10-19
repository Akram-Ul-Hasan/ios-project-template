import Foundation
import Security

/// Keychain access behind a protocol so tests and previews use `InMemoryKeychain`.
public protocol KeychainStoring: Sendable {
    func data(for key: KeychainKey) throws(KeychainError) -> Data?
    func set(_ data: Data, for key: KeychainKey, protection: KeychainProtection) throws(KeychainError)
    func remove(_ key: KeychainKey) throws(KeychainError)
}

extension KeychainStoring {
    public func set(_ data: Data, for key: KeychainKey) throws(KeychainError) {
        try set(data, for: key, protection: .standard)
    }

    public func remove(_ keys: [KeychainKey]) throws(KeychainError) {
        for key in keys {
            try remove(key)
        }
    }
}

public enum KeychainProtection: Sendable {
    /// Readable after the first unlock since boot, this device only: not in backups, not migrated to a new phone.
    case standard
    /// Also needs Face ID / Touch ID on every read; invalidated if biometrics are re-enrolled.
    case biometryCurrentSet
}

public enum KeychainError: Error, Equatable, Sendable {
    case unexpectedStatus(OSStatus)
    case accessControlUnavailable
}

/// Generic-password items keyed by `KeychainKey`, all under one service (the bundle id).
public struct KeychainService: KeychainStoring {
    private let service: String
    private let accessGroup: String?

    /// `accessGroup`: set to the shared Keychain group when app extensions need the items.
    public init(
        service: String = Bundle.main.bundleIdentifier ?? "com.technonext.projecttemplate", accessGroup: String?
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }

    public func data(for key: KeychainKey) throws(KeychainError) -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw .unexpectedStatus(status)
        }
    }

    public func set(_ data: Data, for key: KeychainKey, protection: KeychainProtection) throws(KeychainError) {
        // Delete + add (instead of update) so a change of protection always takes effect.
        try remove(key)
        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        switch protection {
        case .standard:
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .biometryCurrentSet:
            guard
                let access = SecAccessControlCreateWithFlags(
                    nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .biometryCurrentSet, nil)
            else { throw .accessControlUnavailable }
            query[kSecAttrAccessControl as String] = access
        }
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw .unexpectedStatus(status) }
    }

    public func remove(_ key: KeychainKey) throws(KeychainError) {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw .unexpectedStatus(status) }
    }

    private func baseQuery(for key: KeychainKey) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecUseDataProtectionKeychain as String: true,
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        return query
    }
}
