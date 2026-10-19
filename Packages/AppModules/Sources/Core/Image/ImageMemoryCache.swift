import Foundation

/// Decoded images in memory, cost-limited. NSCache evicts automatically under memory pressure.
public final class ImageMemoryCache: @unchecked Sendable {
    // @unchecked: NSCache is thread-safe.
    private let cache = NSCache<NSString, Entry>()

    public init(
        costLimit: Int = CacheConstants.imageMemoryCostLimit, countLimit: Int = CacheConstants.imageMemoryCountLimit
    ) {
        cache.totalCostLimit = costLimit
        cache.countLimit = countLimit
    }

    func image(for key: String) -> PipelineImage? {
        cache.object(forKey: key as NSString)?.image
    }

    func insert(_ image: PipelineImage, for key: String) {
        cache.setObject(Entry(image), forKey: key as NSString, cost: image.cost)
    }

    func removeAll() {
        cache.removeAllObjects()
    }

    private final class Entry {
        let image: PipelineImage
        init(_ image: PipelineImage) { self.image = image }
    }
}
