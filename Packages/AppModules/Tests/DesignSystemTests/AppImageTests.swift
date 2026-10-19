import CoreGraphics
import Testing

@testable import DesignSystem

@Suite("AppImage")
@MainActor
struct AppImageTests {
    @Test(
        "Requests the longest side in pixels, rounded up to 64",
        arguments: [
            (CGSize.zero, 3.0, 0), (CGSize(width: 160, height: 120), 3, 512), (CGSize(width: 100, height: 300), 2, 640),
            (CGSize(width: 64, height: 64), 1, 64),
        ])
    func pixelSize(size: CGSize, scale: CGFloat, expected: Int) {
        #expect(AppImage<ImagePlaceholder>.pixelSize(for: size, scale: scale) == expected)
    }

    @Test("Avatar initials use the first letters of the first two words")
    func initials() {
        #expect(AvatarView.initials(of: "Rahim Uddin Ahmed") == "RU")
        #expect(AvatarView.initials(of: "  karim ") == "K")
        #expect(AvatarView.initials(of: "") == "")
    }
}
