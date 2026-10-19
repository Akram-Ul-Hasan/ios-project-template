import SwiftUI

/// Semantic colours (rule 6). Each is a colour set with Any + Dark appearances in `Resources/Colors.xcassets`,
/// read through Xcode's generated symbols, never by string name. Replace the hex values with the Figma palette.
public enum AppColors {
    public static let brandPrimary = Color(.brandPrimary)
    /// Text and icons on `brandPrimary`.
    public static let onPrimary = Color(.onPrimary)

    public static let background = Color(.background)
    public static let surface = Color(.surface)
    public static let surfaceVariant = Color(.surfaceVariant)

    public static let textPrimary = Color(.textPrimary)
    public static let textSecondary = Color(.textSecondary)
    public static let textDisabled = Color(.textDisabled)

    public static let border = Color(.border)
    public static let divider = Color(.divider)

    public static let success = Color(.success)
    public static let error = Color(.error)
    public static let warning = Color(.warning)
    public static let info = Color(.info)

    /// Placeholder blocks while loading.
    public static let skeleton = Color(.skeleton)
    /// Dimmed backdrop behind popups and loading overlays.
    public static let scrim = Color(.scrim)
}
