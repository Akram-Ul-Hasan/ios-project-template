import Foundation

/// Sensitive data larger than a token (cached profile, saved card metadata): Codable → JSON → AES-GCM → file
/// with complete file protection, excluded from backups (§6g).
public struct EncryptedFileStore: Sendable {
    private let directory: URL
    private let encryption: any EncryptionManager

    public init(directory: URL, encryption: any EncryptionManager) {
        self.directory = directory
        self.encryption = encryption
    }

    /// `Application Support/Secure`, created on first use.
    public static func defaultDirectory() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        .appending(path: "Secure", directoryHint: .isDirectory)
    }

    public func save<Value: Encodable>(_ value: Value, as name: String) throws {
        try prepareDirectory()
        let sealed = try encryption.encrypt(try JSONEncoder().encode(value))
        try sealed.write(to: fileURL(name), options: Self.writingOptions)
    }

    /// `nil` when nothing is stored under `name`.
    public func load<Value: Decodable>(_ type: Value.Type, from name: String) throws -> Value? {
        let url = fileURL(name)
        guard FileManager.default.fileExists(atPath: url.path()) else { return nil }
        return try JSONDecoder().decode(Value.self, from: try encryption.decrypt(Data(contentsOf: url)))
    }

    public func remove(_ name: String) throws {
        let url = fileURL(name)
        guard FileManager.default.fileExists(atPath: url.path()) else { return }
        try FileManager.default.removeItem(at: url)
    }

    public func removeAll() throws {
        guard FileManager.default.fileExists(atPath: directory.path()) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    private func fileURL(_ name: String) -> URL {
        directory.appending(path: "\(name).enc", directoryHint: .notDirectory)
    }

    private func prepareDirectory() throws {
        guard !FileManager.default.fileExists(atPath: directory.path()) else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var url = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }

    private static var writingOptions: Data.WritingOptions {
        #if os(iOS)
            [.atomic, .completeFileProtection]
        #else
            [.atomic]
        #endif
    }
}
