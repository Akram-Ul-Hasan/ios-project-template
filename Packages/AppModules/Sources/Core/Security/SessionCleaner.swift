/// Anything holding user data that must go on logout (§6g).
public protocol SessionCleanable: Sendable {
    func clearSessionData() async throws
}

/// Wipes every registered store on logout: Keychain session, encrypted files, user preferences, Core Data,
/// image cache. One failing store never stops the others.
public struct SessionCleaner: Sendable {
    private let cleanables: [any SessionCleanable]

    public init(cleanables: [any SessionCleanable]) {
        self.cleanables = cleanables
    }

    public func clean() async {
        for cleanable in cleanables {
            do {
                try await cleanable.clearSessionData()
            } catch {
                let name = String(describing: type(of: cleanable))
                AppLogger.security.error("session wipe failed for \(name, privacy: .public)")
            }
        }
    }
}

extension SecureTokenStore: SessionCleanable {
    public func clearSessionData() async throws { try clear() }
}

extension EncryptedFileStore: SessionCleanable {
    public func clearSessionData() async throws { try removeAll() }
}

extension CodablePreferencesStore: SessionCleanable {
    public func clearSessionData() async throws { removeAll(scope: .user) }
}
