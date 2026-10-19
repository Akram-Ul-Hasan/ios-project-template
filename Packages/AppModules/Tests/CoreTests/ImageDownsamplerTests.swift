import Foundation
import TestSupport
import Testing

@testable import Core

@Suite("ImageDownsampler")
struct ImageDownsamplerTests {
    private let photo = TestImage.png(width: 2_000, height: 1_000)

    @Test("Decodes to the requested longest side, keeping the aspect ratio")
    func downsample() throws {
        let image = try #require(ImageDownsampler.decode(photo, maxPixelSize: 400))
        #expect(image.width == 400)
        #expect(image.height == 200)
    }

    @Test("nil size decodes at full size; garbage decodes to nil")
    func fullSizeAndGarbage() {
        #expect(ImageDownsampler.decode(photo, maxPixelSize: nil)?.width == 2_000)
        #expect(ImageDownsampler.decode(Data("not an image".utf8), maxPixelSize: 100) == nil)
    }
}
