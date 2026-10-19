import SwiftUI

/// A toolbar button for `commonAppBar`. At most two per screen.
public struct AppBarAction: Identifiable {
    public let id = UUID()
    let systemImage: String
    let accessibilityLabel: String
    let badge: Int?
    let action: () -> Void

    public init(systemImage: String, accessibilityLabel: String, badge: Int? = nil, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.badge = badge
        self.action = action
    }
}

extension View {
    /// Every screen's navigation bar (rule 8): title, optional subtitle, native back (with swipe-back), ≤ 2 actions.
    /// Go back with `@Environment(\.dismiss)` or the router; never a hand-made back button.
    public func commonAppBar(
        _ title: String,
        subtitle: String? = nil,
        showsBack: Bool = true,
        actions: [AppBarAction] = []
    ) -> some View {
        modifier(
            CommonAppBarModifier(
                title: title, subtitle: subtitle, showsBack: showsBack, actions: Array(actions.prefix(2))))
    }

    /// `commonAppBar` with a search field that stays visible under the title.
    public func searchAppBar(_ title: String, text: Binding<String>, prompt: String) -> some View {
        commonAppBar(title)
            #if os(iOS)
                .searchable(text: text, placement: .navigationBarDrawer(displayMode: .always), prompt: prompt)
            #else
                .searchable(text: text, prompt: prompt)
            #endif
    }
}

private struct CommonAppBarModifier: ViewModifier {
    let title: String
    let subtitle: String?
    let showsBack: Bool
    let actions: [AppBarAction]

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(AppColors.surface, for: .navigationBar)
            #endif
            .navigationBarBackButtonHidden(!showsBack)
            .toolbar {
                if let subtitle {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text(title)
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColors.textPrimary)
                            Text(subtitle)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    ForEach(actions) { item in
                        AppIconButton(
                            systemImage: item.systemImage, accessibilityLabel: item.accessibilityLabel,
                            action: item.action
                        )
                        .overlay(alignment: .topTrailing) { BadgeView(count: item.badge) }
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .commonAppBar(
                "Order #1024", subtitle: "Arriving today",
                actions: [
                    AppBarAction(systemImage: "bell", accessibilityLabel: "Notifications", badge: 3) {},
                    AppBarAction(systemImage: "square.and.arrow.up", accessibilityLabel: "Share") {},
                ])
    }
}
