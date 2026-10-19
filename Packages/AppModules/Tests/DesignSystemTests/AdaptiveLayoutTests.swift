#if os(iOS)
    import SwiftUI
    import Testing

    @testable import DesignSystem

    @Suite("AdaptiveLayout")
    @MainActor
    struct AdaptiveLayoutTests {
        @Test(
            "Size classes map to the documented layout table",
            arguments: [
                (UserInterfaceSizeClass.compact, UserInterfaceSizeClass.regular, LayoutClass.portrait),
                (.compact, .compact, .landscape),
                (.regular, .compact, .landscape),
                (.regular, .regular, .tablet),
            ])
        func table(horizontal: UserInterfaceSizeClass, vertical: UserInterfaceSizeClass, expected: LayoutClass) {
            #expect(AdaptiveLayout<EmptyView>.layoutClass(horizontal: horizontal, vertical: vertical) == expected)
        }
    }
#endif
