import SwiftUI

/// The shared look of every button. Use the components (`PrimaryButton`, …) rather than this directly.
public struct AppButtonStyle: ButtonStyle {
    public enum Kind: Sendable {
        /// Filled, the main action of a screen.
        case primary
        /// Outlined, an alternative action.
        case secondary
        /// Text only, low emphasis.
        case text
        /// Filled red, irreversible actions.
        case destructive
    }

    public enum Size: Sendable {
        case regular
        case small
    }

    private let kind: Kind
    private let size: Size
    @Environment(\.isEnabled) private var isEnabled

    public init(kind: Kind, size: Size) {
        self.kind = kind
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size == .regular ? AppTypography.bodyEmphasized : AppTypography.subheadline)
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, size == .regular ? AppSpacing.s24 : AppSpacing.s16)
            .frame(minHeight: size == .regular ? AppSize.buttonHeight : AppSize.buttonHeightSmall)
            .frame(maxWidth: kind == .text ? nil : .infinity)
            .background(background, in: RoundedRectangle(cornerRadius: AppRadius.r12))
            .overlay {
                if kind == .secondary {
                    RoundedRectangle(cornerRadius: AppRadius.r12)
                        .stroke(AppColors.brandPrimary, lineWidth: AppSize.borderWidth)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.r12))
            .opacity(isEnabled ? (configuration.isPressed ? AppOpacity.pressed : 1) : AppOpacity.disabled)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary, .destructive: AppColors.onPrimary
        case .secondary, .text: AppColors.brandPrimary
        }
    }

    private var background: Color {
        switch kind {
        case .primary: AppColors.brandPrimary
        case .destructive: AppColors.error
        case .secondary, .text: .clear
        }
    }
}
