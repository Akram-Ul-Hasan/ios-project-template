import CoreGraphics
import Foundation
import ImageIO

/// Decodes image bytes straight to the size they're shown at (§6d). A 4000 px photo in a 160 pt grid cell
/// decodes to ~480 px instead of 64 MB of pixels.
public enum ImageDownsampler {
    /// `maxPixelSize`: the longest side in pixels (points × display scale); `nil` decodes at full size.
    public static func decode(_ data: Data, maxPixelSize: Int?) -> CGImage? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary)
        else { return nil }
        guard let maxPixelSize, maxPixelSize > 0 else {
            return CGImageSourceCreateImageAtIndex(
                source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
