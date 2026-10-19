import CoreText
import SwiftUI

/// Text styles from Figma. Every style scales with Dynamic Type through its `relativeTo` text style.
public enum AppTypography {
    /// Brand font family, e.g. "Qanelas" (files named `Qanelas-Regular.otf`, `Qanelas-Bold.otf` … in `Resources/Fonts`).
    /// `nil` uses the system font, sized by the text style.
    public static let fontFamily: String? = nil

    public static let largeTitle = font(size: 32, weight: .bold, relativeTo: .largeTitle)
    public static let title1 = font(size: 28, weight: .bold, relativeTo: .title)
    public static let title2 = font(size: 22, weight: .semibold, relativeTo: .title2)
    public static let title3 = font(size: 20, weight: .semibold, relativeTo: .title3)
    public static let headline = font(size: 17, weight: .semibold, relativeTo: .headline)
    public static let body = font(size: 16, weight: .regular, relativeTo: .body)
    public static let bodyEmphasized = font(size: 16, weight: .semibold, relativeTo: .body)
    public static let callout = font(size: 15, weight: .regular, relativeTo: .callout)
    public static let subheadline = font(size: 14, weight: .regular, relativeTo: .subheadline)
    public static let footnote = font(size: 13, weight: .regular, relativeTo: .footnote)
    public static let caption = font(size: 12, weight: .regular, relativeTo: .caption)
    public static let captionEmphasized = font(size: 12, weight: .medium, relativeTo: .caption)

    /// Registers the font files shipped in this module. Call once at launch, before any text renders.
    public static func registerFonts() {
        let urls = ["ttf", "otf"].flatMap { Bundle.module.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func font(size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle) -> Font {
        guard let fontFamily else { return .system(style, weight: weight) }
        return .custom("\(fontFamily)-\(fileSuffix(weight))", size: size, relativeTo: style)
    }

    private static func fileSuffix(_ weight: Font.Weight) -> String {
        switch weight {
        case .bold: "Bold"
        case .semibold: "SemiBold"
        case .medium: "Medium"
        default: "Regular"
        }
    }
}
