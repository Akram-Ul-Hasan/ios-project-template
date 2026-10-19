import Foundation

/// Fetches image bytes for the pipeline. Tests inject a fake.
public protocol ImageDataLoading: Sendable {
    func data(from url: URL) async throws -> Data
}

public struct URLSessionImageLoader: ImageDataLoading {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

public enum ImagePipelineError: Error, Equatable, Sendable {
    case decodingFailed
}

/// Remote images without a third-party library (§6d): memory cache → disk cache → network,
/// one download per URL however many views ask, and decoding downsampled to the view's size.
/// Created once in `AppContainer`, injected into views as `.environment(\.imagePipeline, …)`.
public actor ImagePipeline {
    private let memory: ImageMemoryCache
    private let disk: ImageDiskCache
    private let loader: any ImageDataLoading
    private var inFlight: [String: Task<PipelineImage, any Error>] = [:]
    private var prefetches: [URL: Task<Void, Never>] = [:]

    public init(memory: ImageMemoryCache, disk: ImageDiskCache, loader: any ImageDataLoading) {
        self.memory = memory
        self.disk = disk
        self.loader = loader
    }

    /// Production setup: `Caches/Images` on disk, `URLSession.shared` for downloads.
    public static func makeDefault() throws -> ImagePipeline {
        ImagePipeline(
            memory: ImageMemoryCache(), disk: ImageDiskCache(directory: try ImageDiskCache.defaultDirectory()),
            loader: URLSessionImageLoader())
    }

    /// `maxPixelSize`: the view's longest side in pixels; `nil` for full size.
    public func image(for url: URL, maxPixelSize: Int?) async throws -> PipelineImage {
        let key = "\(url.absoluteString)#\(maxPixelSize ?? 0)"
        if let cached = memory.image(for: key) { return cached }
        if let running = inFlight[key] { return try await running.value }

        let task = Task { [disk, loader] in
            try await Self.fetch(url, maxPixelSize: maxPixelSize, disk: disk, loader: loader)
        }
        inFlight[key] = task
        defer { inFlight[key] = nil }
        let image = try await task.value
        memory.insert(image, for: key)
        return image
    }

    /// Warms the disk cache for rows about to scroll into view.
    public func prefetch(_ urls: [URL]) {
        for url in urls where prefetches[url] == nil {
            prefetches[url] = Task { [disk, loader] in
                defer { self.finishPrefetch(url) }
                guard await !disk.contains(url), !Task.isCancelled else { return }
                if let data = try? await loader.data(from: url), !Task.isCancelled {
                    await disk.store(data, for: url)
                }
            }
        }
    }

    public func cancelPrefetch(_ urls: [URL]) {
        for url in urls {
            prefetches.removeValue(forKey: url)?.cancel()
        }
    }

    /// Keeps the disk cache under its size limit. Run at launch or from the cleanup background task.
    public func trimDiskCache() async {
        await disk.trim()
    }

    private func finishPrefetch(_ url: URL) {
        prefetches[url] = nil
    }

    // Off the actor: disk reads, downloads and decoding run in parallel for different URLs.
    @concurrent
    private static func fetch(
        _ url: URL,
        maxPixelSize: Int?,
        disk: ImageDiskCache,
        loader: any ImageDataLoading
    ) async throws -> PipelineImage {
        let data: Data
        if let cached = await disk.data(for: url) {
            data = cached
        } else {
            data = try await loader.data(from: url)
            await disk.store(data, for: url)
        }
        guard let cgImage = ImageDownsampler.decode(data, maxPixelSize: maxPixelSize) else {
            AppLogger.ui.error("image decode failed for \(url.lastPathComponent, privacy: .public)")
            throw ImagePipelineError.decodingFailed
        }
        return PipelineImage(cgImage: cgImage)
    }
}

extension ImagePipeline: SessionCleanable {
    public func clearSessionData() async throws {
        memory.removeAll()
        try await disk.removeAll()
    }
}
