import Foundation
import TestSupport
import Testing

@testable import Core

@Suite("EncryptedFileStore")
struct EncryptedFileStoreTests {
    private struct Profile: Codable, Equatable {
        let name: String
        let phone: String
    }

    private let directory = FileManager.default.temporaryDirectory.appending(path: "secure-\(UUID().uuidString)")

    private func makeStore() throws -> EncryptedFileStore {
        EncryptedFileStore(directory: directory, encryption: try AESGCMEncryptionManager(keychain: InMemoryKeychain()))
    }

    @Test("Saves encrypted, loads back, excludes the folder from backup")
    func roundTrip() throws {
        let store = try makeStore()
        defer { try? store.removeAll() }
        let profile = Profile(name: "Rahim", phone: "01712345678")

        try store.save(profile, as: "profile")
        let raw = try Data(contentsOf: directory.appending(path: "profile.enc"))
        #expect(raw.range(of: Data("01712345678".utf8)) == nil)
        #expect(try store.load(Profile.self, from: "profile") == profile)
        #expect(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
    }

    @Test("Missing files load as nil; remove and removeAll delete")
    func removal() throws {
        let store = try makeStore()
        #expect(try store.load(Profile.self, from: "nothing") == nil)
        try store.save(Profile(name: "a", phone: "b"), as: "one")
        try store.save(Profile(name: "c", phone: "d"), as: "two")
        try store.remove("one")
        #expect(try store.load(Profile.self, from: "one") == nil)
        try store.removeAll()
        #expect(try store.load(Profile.self, from: "two") == nil)
    }
}
