import SwiftUI

/// The main action of a screen. Full width; pass `isLoading` to show a spinner and block taps.
public struct PrimaryButton: View {
    private let title: String
    private let systemImage: String?
    private let size: AppButtonStyle.Size
    private let isLoading: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        systemImage: String? = nil,
        size: AppButtonStyle.Size = .regular,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        AppButton(title, systemImage: systemImage, kind: .primary, size: size, isLoading: isLoading, action: action)
    }
}

/// An alternative action, outlined.
public struct SecondaryButton: View {
    private let title: String
    private let systemImage: String?
    private let size: AppButtonStyle.Size
    private let action: () -> Void

    public init(
        _ title: String, systemImage: String? = nil, size: AppButtonStyle.Size = .regular, action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }

    public var body: some View {
        AppButton(title, systemImage: systemImage, kind: .secondary, size: size, isLoading: false, action: action)
    }
}

/// A low-emphasis text action ("Forgot password?", "See all").
public struct AppTextButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        AppButton(title, systemImage: nil, kind: .text, size: .small, isLoading: false, action: action)
    }
}

/// An icon-only button with a full 44 pt tap target. `accessibilityLabel` is required: VoiceOver has nothing else to read.
public struct AppIconButton: View {
    private let systemImage: String
    private let accessibilityLabel: String
    private let action: () -> Void

    public init(systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: AppIconSize.s20, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: AppSize.minTapTarget, height: AppSize.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

struct AppButton: View {
    let title: String
    let systemImage: String?
    let kind: AppButtonStyle.Kind
    let size: AppButtonStyle.Size
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String?,
        kind: AppButtonStyle.Kind,
        size: AppButtonStyle.Size,
        isLoading: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.kind = kind
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Label {
                    Text(title)
                } icon: {
                    if let systemImage { Image(systemName: systemImage) }
                }
                .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(
                        kind == .primary || kind == .destructive ? AppColors.onPrimary : AppColors.brandPrimary)
                }
            }
        }
        .buttonStyle(AppButtonStyle(kind: kind, size: size))
        .allowsHitTesting(!isLoading)
        .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
    }
}

#Preview("Buttons") {
    VStack(spacing: AppSpacing.s12) {
        PrimaryButton("Place order", systemImage: "cart") {}
        PrimaryButton("Placing…", isLoading: true) {}
        SecondaryButton("Add to wishlist") {}
        PrimaryButton("Disabled") {}.disabled(true)
        HStack {
            AppTextButton("Forgot password?") {}
            Spacer()
            AppIconButton(systemImage: "heart", accessibilityLabel: "Wishlist") {}
        }
    }
    .padding(AppSpacing.s16)
}

#Preview("Buttons, dark") {
    VStack(spacing: AppSpacing.s12) {
        PrimaryButton("Place order") {}
        SecondaryButton("Add to wishlist") {}
    }
    .padding(AppSpacing.s16)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
