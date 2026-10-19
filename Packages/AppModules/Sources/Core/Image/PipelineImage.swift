import CoreGraphics

/// A decoded, display-ready image. Platform-neutral so Core stays free of UIKit;
/// DesignSystem shows it with `Image(decorative: cgImage, scale: 1)`.
public struct PipelineImage: Sendable {
    public let cgImage: CGImage

    public init(cgImage: CGImage) {
        self.cgImage = cgImage
    }

    /// Approximate decoded size in bytes, used as the memory-cache cost.
    var cost: Int { cgImage.bytesPerRow * cgImage.height }
}
