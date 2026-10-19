import Core
import SwiftUI

extension EnvironmentValues {
    /// Set once at the root: `.environment(\.imagePipeline, container.imagePipeline)`.
    @Entry public var imagePipeline: ImagePipeline?
}

/// Every remote image (rule 13; never `AsyncImage`): cached in memory and on disk, one download per URL,
/// decoded at the size it's shown, cancelled when the view disappears (§6d). Size it from outside:
/// `AppImage(url: product.imageURL).aspectRatio(1, contentMode: .fit)`.
public struct AppImage<Fallback: View>: View {
    private let url: URL?
    private let contentMode: ContentMode
    private let accessibilityLabel: String?
    private let fallback: Fallback

    @Environment(\.imagePipeline) private var pipeline
    @Environment(\.displayScale) private var displayScale
    @State private var size: CGSize = .zero
    @State private var phase: Phase = .loading

    private enum Phase {
        case loading
        case success(PipelineImage)
        case failure
    }

    /// `accessibilityLabel`: set for meaningful images; `nil` hides decorative ones from VoiceOver.
    public init(
        url: URL?,
        contentMode: ContentMode = .fill,
        accessibilityLabel: String? = nil,
        @ViewBuilder fallback: () -> Fallback
    ) {
        self.url = url
        self.contentMode = contentMode
        self.accessibilityLabel = accessibilityLabel
        self.fallback = fallback()
    }

    public var body: some View {
        Color.clear
            .overlay { content }
            .clipped()
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: {
                size = $0
            }
            .task(id: LoadKey(url: url, pixels: Self.pixelSize(for: size, scale: displayScale))) { await load() }
            .accessibilityHidden(accessibilityLabel == nil)
            .accessibilityLabel(accessibilityLabel ?? "")
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            Rectangle().fill(AppColors.skeleton)
        case .success(let image):
            Image(decorative: image.cgImage, scale: 1)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .transition(.opacity)
        case .failure:
            fallback
        }
    }

    private func load() async {
        let pixels = Self.pixelSize(for: size, scale: displayScale)
        guard let url, let pipeline else {
            phase = .failure
            return
        }
        guard pixels > 0 else { return }  // not laid out yet
        do {
            let image = try await pipeline.image(for: url, maxPixelSize: pixels)
            withAnimation(AppAnimation.fast) { phase = .success(image) }
        } catch {
            guard !Task.isCancelled else { return }  // scrolled away: not a failure
            phase = .failure
        }
    }

    /// Longest side in pixels, rounded up to 64 so small layout changes reuse the cached decode.
    static func pixelSize(for size: CGSize, scale: CGFloat) -> Int {
        let pixels = Int((max(size.width, size.height) * scale).rounded(.up))
        guard pixels > 0 else { return 0 }
        return ((pixels + 63) / 64) * 64
    }

    private struct LoadKey: Equatable {
        let url: URL?
        let pixels: Int
    }
}

extension AppImage where Fallback == ImagePlaceholder {
    public init(url: URL?, contentMode: ContentMode = .fill, accessibilityLabel: String? = nil) {
        self.init(url: url, contentMode: contentMode, accessibilityLabel: accessibilityLabel) { ImagePlaceholder() }
    }
}

/// Shown when there's no image or it failed to load.
public struct ImagePlaceholder: View {
    public init() {}

    public var body: some View {
        ZStack {
            AppColors.surfaceVariant
            Image(systemName: "photo")
                .font(.system(size: AppIconSize.s24))
                .foregroundStyle(AppColors.textDisabled)
        }
    }
}

#Preview {
    HStack(spacing: AppSpacing.s16) {
        AppImage(url: nil).frame(width: 120, height: 120).clipShape(RoundedRectangle(cornerRadius: AppRadius.r12))
        AppImage(url: URL(string: "https://picsum.photos/400"))
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.r12))
    }
    .environment(\.imagePipeline, try? ImagePipeline.makeDefault())
}
