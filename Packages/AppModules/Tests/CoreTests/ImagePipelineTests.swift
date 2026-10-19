import Foundation
import TestSupport
import Testing
import os

@testable import Core

@Suite("ImagePipeline")
struct ImagePipelineTests {
    private final class Loader: ImageDataLoading {
        let calls = OSAllocatedUnfairLock(initialState: 0)
        let payload: Data
        init(_ payload: Data = TestImage.png(width: 800, height: 400)) { self.payload = payload }
        func data(from url: URL) async throws -> Data {
            calls.withLock { $0 += 1 }
            try await Task.sleep(for: .milliseconds(20))
            return payload
        }
        var count: Int { calls.withLock { $0 } }
    }

    private let directory = FileManager.default.temporaryDirectory.appending(path: "pipeline-\(UUID().uuidString)")
    private let url = URL(string: "https://cdn.test/p.png")!

    private func pipeline(_ loader: Loader) -> ImagePipeline {
        ImagePipeline(memory: ImageMemoryCache(), disk: ImageDiskCache(directory: directory), loader: loader)
    }

    @Test("Twenty simultaneous requests for one URL download once")
    func dedupe() async throws {
        let loader = Loader()
        let pipeline = pipeline(loader)
        try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<20 { group.addTask { try await pipeline.image(for: url, maxPixelSize: 100).cgImage.width } }
            for try await width in group { #expect(width == 100) }
        }
        #expect(loader.count == 1)
    }

    @Test("Memory, then disk, serve repeat requests")
    func caches() async throws {
        let loader = Loader()
        _ = try await pipeline(loader).image(for: url, maxPixelSize: 200)
        let reused = pipeline(loader)  // new memory cache, same disk directory
        _ = try await reused.image(for: url, maxPixelSize: 200)
        _ = try await reused.image(for: url, maxPixelSize: 200)
        #expect(loader.count == 1)
    }

    @Test("Undecodable bytes throw")
    func decodingFailure() async {
        let pipeline = pipeline(Loader(Data("<html>".utf8)))
        await #expect(throws: ImagePipelineError.decodingFailed) {
            try await pipeline.image(for: url, maxPixelSize: 50)
        }
    }

    @Test("Prefetch fills the disk cache so the later load is free")
    func prefetch() async throws {
        let loader = Loader()
        let pipeline = pipeline(loader)
        await pipeline.prefetch([url])
        try await Task.sleep(for: .milliseconds(200))
        _ = try await pipeline.image(for: url, maxPixelSize: 80)
        #expect(loader.count == 1)
    }

    @Test("Logout clears both caches")
    func clear() async throws {
        let loader = Loader()
        let pipeline = pipeline(loader)
        _ = try await pipeline.image(for: url, maxPixelSize: 80)
        try await pipeline.clearSessionData()
        _ = try await pipeline.image(for: url, maxPixelSize: 80)
        #expect(loader.count == 2)
    }
}
