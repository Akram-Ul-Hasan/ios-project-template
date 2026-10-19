import SwiftUI

/// Renders a screen in every configuration it must survive (§2a), in one preview:
/// `#Preview { PreviewMatrix { LoginScreen(viewModel: .preview) } }`.
public struct PreviewMatrix<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: AppSpacing.s24) {
                ForEach(PreviewVariant.allCases) { variant in
                    VStack(alignment: .leading, spacing: AppSpacing.s8) {
                        Text(verbatim: variant.label)
                            .font(AppTypography.captionEmphasized)
                            .foregroundStyle(AppColors.textSecondary)
                        content()
                            .frame(width: variant.size.width, height: variant.size.height)
                            .background(AppColors.background)
                            .modifier(PreviewVariantModifier(variant: variant))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.r16))
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.r16).stroke(AppColors.border))
                    }
                }
            }
            .padding(AppSpacing.s24)
        }
    }
}

enum PreviewVariant: String, CaseIterable, Identifiable {
    case smallPhone
    case maxLandscape
    case iPad
    case iPadSplit
    case largeText
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .smallPhone: "iPhone SE"
        case .maxLandscape: "Pro Max landscape"
        case .iPad: "iPad"
        case .iPadSplit: "iPad split (narrow)"
        case .largeText: "Accessibility XL text"
        case .dark: "Dark"
        }
    }

    /// Window sizes in points.
    var size: CGSize {
        switch self {
        case .smallPhone: CGSize(width: 375, height: 667)
        case .maxLandscape: CGSize(width: 956, height: 440)
        case .iPad: CGSize(width: 820, height: 1180)
        case .iPadSplit: CGSize(width: 320, height: 1180)
        case .largeText, .dark: CGSize(width: 402, height: 874)
        }
    }
}

private struct PreviewVariantModifier: ViewModifier {
    let variant: PreviewVariant

    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(variant == .largeText ? .accessibility2 : .large)
            .environment(\.colorScheme, variant == .dark ? .dark : .light)
            #if os(iOS)
                .environment(\.horizontalSizeClass, variant == .iPad || variant == .maxLandscape ? .regular : .compact)
                .environment(\.verticalSizeClass, variant == .maxLandscape ? .compact : .regular)
            #endif
    }
}

#Preview {
    PreviewMatrix {
        VStack(spacing: AppSpacing.s16) {
            Text(verbatim: "Title").font(AppTypography.title2)
            Text(verbatim: "Body text that wraps across lines when the text is large.").font(AppTypography.body)
        }
        .foregroundStyle(AppColors.textPrimary)
        .padding(AppSpacing.s16)
    }
}
