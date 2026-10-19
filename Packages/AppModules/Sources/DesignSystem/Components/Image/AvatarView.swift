import SwiftUI

/// Round profile picture; the person's initials when there's no photo or it fails to load.
public struct AvatarView: View {
    private let url: URL?
    private let name: String
    private let size: CGFloat
    /// Initials are 40% of the avatar diameter.
    private static let initialsScale: CGFloat = 0.4

    public init(url: URL?, name: String, size: CGFloat = AppSize.avatar) {
        self.url = url
        self.name = name
        self.size = size
    }

    public var body: some View {
        AppImage(url: url) {
            ZStack {
                AppColors.brandPrimary
                Text(Self.initials(of: name))
                    .font(.system(size: size * Self.initialsScale, weight: .semibold))
                    .foregroundStyle(AppColors.onPrimary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
    }

    /// "Rahim Uddin Ahmed" → "RU", "rahim" → "R".
    static func initials(of name: String) -> String {
        name.split(whereSeparator: \.isWhitespace).prefix(2).compactMap(\.first).map { String($0).uppercased() }
            .joined()
    }
}

#Preview {
    HStack(spacing: AppSpacing.s16) {
        AvatarView(url: nil, name: "Rahim Uddin", size: AppSize.avatarSmall)
        AvatarView(url: nil, name: "Karim")
        AvatarView(url: nil, name: "Nusrat Jahan", size: AppSize.avatarLarge)
    }
}
