import SwiftUI

/// Motion tokens. Toast/snackbar display durations live with `FeedbackMessage` in Core.
public enum AppAnimation {
    public static let fast: Animation = .easeOut(duration: 0.15)
    public static let standard: Animation = .easeInOut(duration: 0.25)
    public static let slow: Animation = .easeInOut(duration: 0.4)
    /// Popups and banners appearing.
    public static let spring: Animation = .spring(duration: 0.35, bounce: 0.2)
    /// One sweep of the skeleton shimmer.
    public static let shimmerDuration: Double = 1.2
}
