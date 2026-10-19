import SwiftUI

/// Elevation tokens: `.appShadow(.medium)`.
public struct AppShadow: Sendable {
    public let opacity: Double
    public let radius: CGFloat
    public let y: CGFloat

    public static let small = AppShadow(opacity: 0.06, radius: 4, y: 1)
    public static let medium = AppShadow(opacity: 0.10, radius: 12, y: 4)
    public static let large = AppShadow(opacity: 0.16, radius: 24, y: 8)
}

extension View {
    public func appShadow(_ shadow: AppShadow) -> some View {
        self.shadow(color: .black.opacity(shadow.opacity), radius: shadow.radius, x: 0, y: shadow.y)
    }
}
