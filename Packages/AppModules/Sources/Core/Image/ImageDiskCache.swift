import CryptoKit
import Foundation

/// Downloaded image bytes in `Caches/Images/<sha256(url)>`, trimmed least-recently-used first.
public actor ImageDiskCache {
    private let directory: URL
    private let sizeLimit: Int
    private let fileManager = FileManager.default

    public init(directory: URL, sizeLimit: Int = CacheConstants.imageDiskSizeLimit) {
        self.directory = directory
        self.sizeLimit = sizeLimit
    }

    public static func defaultDirectory() throws -> URL {
        try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: "Images", directoryHint: .isDirectory)
    }

    func data(for url: URL) -> Data? {
        let file = fileURL(for: url)
        guard let data = try? Data(contentsOf: file) else { return nil }
        // Reading counts as use, for LRU trimming.
        try? fileManager.setAttributes([.modificationDate: Date.now], ofItemAtPath: file.path())
        return data
    }

    func contains(_ url: URL) -> Bool {
        fileManager.fileExists(atPath: fileURL(for: url).path())
    }

    func store(_ data: Data, for url: URL) {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL(for: url), options: .atomic)
        } catch {
            AppLogger.persistence.error("image cache write failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Deletes the least recently used files until the cache fits `sizeLimit`. Run at launch.
    public func trim() {
        let keys: [URLResourceKey] = [.contentModificationDateKey, .totalFileAllocatedSizeKey]
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys) else {
            return
        }
        let entries = files.compactMap { file -> (url: URL, date: Date, size: Int)? in
            guard let values = try? file.resourceValues(forKeys: Set(keys)) else { return nil }
            return (file, values.contentModificationDate ?? .distantPast, values.totalFileAllocatedSize ?? 0)
        }
        var total = entries.reduce(0) { $0 + $1.size }
        for entry in entries.sorted(by: { $0.date < $1.date }) where total > sizeLimit {
            try? fileManager.removeItem(at: entry.url)
            total -= entry.size
        }
    }

    public func removeAll() throws {
        guard fileManager.fileExists(atPath: directory.path()) else { return }
        try fileManager.removeItem(at: directory)
    }

    private func fileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8)).map { ($0 < 16 ? "0" : "") + String($0, radix: 16) }
            .joined()
        return directory.appending(path: hash, directoryHint: .notDirectory)
    }
}
