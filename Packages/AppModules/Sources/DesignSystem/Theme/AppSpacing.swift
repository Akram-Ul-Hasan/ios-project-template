import CoreGraphics

/// Spacing tokens: plain point values straight from Figma, no scaling (§2a, rule 5). Names match the Figma tokens.
public enum AppSpacing {
    public static let s2: CGFloat = 2
    public static let s4: CGFloat = 4
    public static let s6: CGFloat = 6
    public static let s8: CGFloat = 8
    public static let s12: CGFloat = 12
    public static let s16: CGFloat = 16
    public static let s20: CGFloat = 20
    public static let s24: CGFloat = 24
    public static let s32: CGFloat = 32
    public static let s40: CGFloat = 40
    /// Max width for forms and reading text on iPad.
    public static let readableWidth: CGFloat = 600
}
