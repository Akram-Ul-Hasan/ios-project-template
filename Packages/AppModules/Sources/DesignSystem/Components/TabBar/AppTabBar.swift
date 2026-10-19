import SwiftUI

public struct AppTabBarItem<ID: Hashable>: Identifiable {
    public let id: ID
    let title: String
    let systemImage: String
    let selectedSystemImage: String
    let badge: Int?

    public init(id: ID, title: String, systemImage: String, selectedSystemImage: String? = nil, badge: Int? = nil) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.selectedSystemImage = selectedSystemImage ?? systemImage
        self.badge = badge
    }
}

/// The custom Figma tab bar (§6b). Hide the native one with `.toolbar(.hidden, for: .tabBar)` and place this
/// at the bottom. Tapping the selected tab calls `onReselect` (pop to root).
public struct AppTabBar<ID: Hashable>: View {
    private let items: [AppTabBarItem<ID>]
    @Binding private var selection: ID
    private let onReselect: (ID) -> Void

    public init(items: [AppTabBarItem<ID>], selection: Binding<ID>, onReselect: @escaping (ID) -> Void) {
        self.items = items
        _selection = selection
        self.onReselect = onReselect
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let isSelected = item.id == selection
                TapArea {
                    if isSelected { onReselect(item.id) } else { selection = item.id }
                } label: {
                    VStack(spacing: AppSpacing.s4) {
                        Image(systemName: isSelected ? item.selectedSystemImage : item.systemImage)
                            .font(.system(size: AppIconSize.s24))
                            .overlay(alignment: .topTrailing) {
                                BadgeView(count: item.badge).offset(x: AppSpacing.s12, y: -AppSpacing.s6)
                            }
                        Text(item.title)
                            .font(AppTypography.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(isSelected ? AppColors.brandPrimary : AppColors.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: AppSize.tabBarHeight)
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityValue(item.badge.map { Text($0, format: .number) } ?? Text(verbatim: ""))
            }
        }
        .background(alignment: .top) {
            AppColors.surface
                .overlay(alignment: .top) { AppDivider() }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    @Previewable @State var tab = 0
    VStack {
        Spacer()
        AppTabBar(
            items: [
                AppTabBarItem(id: 0, title: "Home", systemImage: "house", selectedSystemImage: "house.fill"),
                AppTabBarItem(id: 1, title: "Categories", systemImage: "square.grid.2x2"),
                AppTabBarItem(id: 2, title: "Cart", systemImage: "cart", selectedSystemImage: "cart.fill", badge: 3),
                AppTabBarItem(id: 3, title: "Account", systemImage: "person", selectedSystemImage: "person.fill"),
            ],
            selection: $tab, onReselect: { _ in })
    }
}
