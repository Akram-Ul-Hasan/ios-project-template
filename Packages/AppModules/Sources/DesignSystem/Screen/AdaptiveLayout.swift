import SwiftUI

public enum LayoutClass: Sendable {
    case portrait
    case landscape
    case tablet
}

/// Opt-in (§2a): only for screens with a distinct landscape/tablet design. Every other screen is one adaptive view.
/// ```
/// AdaptiveLayout { layout in
///     if layout == .tablet { HomeTabletView(viewModel: viewModel) } else { HomeView(viewModel: viewModel) }
/// }
/// ```
/// Size classes are window-based, so iPad Split View gets the phone layout when narrow.
public struct AdaptiveLayout<Content: View>: View {
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontal
        @Environment(\.verticalSizeClass) private var vertical
    #endif
    private let content: (LayoutClass) -> Content

    public init(@ViewBuilder content: @escaping (LayoutClass) -> Content) {
        self.content = content
    }

    public var body: some View {
        #if os(iOS)
            content(Self.layoutClass(horizontal: horizontal, vertical: vertical))
        #else
            content(.tablet)
        #endif
    }

    #if os(iOS)
        static func layoutClass(horizontal: UserInterfaceSizeClass?, vertical: UserInterfaceSizeClass?) -> LayoutClass {
            if horizontal == .regular && vertical == .regular { return .tablet }
            if vertical == .compact { return .landscape }
            return .portrait
        }
    #endif
}
