import Foundation

/// Cache sizes and lifetimes (§6o).
public enum CacheConstants {
    public static let imageMemoryCostLimit = 50 * 1024 * 1024
    public static let imageMemoryCountLimit = 300
    public static let imageDiskSizeLimit = 200 * 1024 * 1024
    /// Cached remote lists older than this are refreshed when the screen appears.
    public static let defaultTTL: TimeInterval = 5 * 60
}
