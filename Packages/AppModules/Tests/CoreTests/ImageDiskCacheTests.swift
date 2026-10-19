import Foundation
import Testing

@testable import Core

@Suite("ImageDiskCache")
struct ImageDiskCacheTests {
    private let directory = FileManager.default.temporaryDirectory.appending(path: "images-\(UUID().uuidString)")
    private let a = URL(string: "https://cdn.test/a.jpg")!
    private let b = URL(string: "https://cdn.test/b.jpg")!
    private let c = URL(string: "https://cdn.test/c.jpg")!

    @Test("Stores and reads by URL")
    func roundTrip() async throws {
        let cache = ImageDiskCache(directory: directory)
        defer { try? FileManager.default.removeItem(at: directory) }
        #expect(await cache.data(for: a) == nil)
        await cache.store(Data([1, 2, 3]), for: a)
        #expect(await cache.data(for: a) == Data([1, 2, 3]))
        #expect(await cache.contains(a))
        try await cache.removeAll()
        #expect(await !cache.contains(a))
    }

    @Test("Trim removes least recently used files first")
    func trim() async throws {
        let cache = ImageDiskCache(directory: directory, sizeLimit: 10_000)
        defer { try? FileManager.default.removeItem(at: directory) }
        let chunk = Data(repeating: 7, count: 4_096)
        for url in [a, b, c] {
            await cache.store(chunk, for: url)
        }
        // Make `a` oldest-used, then touch `b` by reading it.
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for file in files {
            try FileManager.default.setAttributes([.modificationDate: Date.distantPast], ofItemAtPath: file.path())
        }
        _ = await cache.data(for: b)
        _ = await cache.data(for: c)
        await cache.trim()
        #expect(await !cache.contains(a))
        #expect(await cache.contains(b))
        #expect(await cache.contains(c))
    }
}
