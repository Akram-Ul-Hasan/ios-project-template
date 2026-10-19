import Core
import SwiftUI

/// Short neutral info: a capsule at the bottom, no action.
public struct ToastView: View {
    private let message: FeedbackMessage

    public init(message: FeedbackMessage) {
        self.message = message
    }

    public var body: some View {
        Text(message.text)
            .font(AppTypography.subheadline)
            .foregroundStyle(AppColors.background)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.s16)
            .padding(.vertical, AppSpacing.s12)
            .background(AppColors.textPrimary, in: Capsule())
            .appShadow(.medium)
            .accessibilityElement(children: .combine)
    }
}

/// A result that may need an action: full width, kind colour and icon, optional button, swipe down to dismiss.
public struct SnackBarView: View {
    private let message: FeedbackMessage
    private let onAction: () -> Void
    private let onDismiss: () -> Void
    @State private var dragOffset: CGFloat = 0

    public init(message: FeedbackMessage, onAction: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.message = message
        self.onAction = onAction
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: AppSpacing.s12) {
            Image(systemName: icon)
                .font(.system(size: AppIconSize.s20, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(message.text)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let action = message.action {
                Button(action.title, action: onAction)
                    .font(AppTypography.bodyEmphasized)
                    .foregroundStyle(AppColors.brandPrimary)
                    .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(AppSpacing.s16)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.r12))
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: AppRadius.r12, bottomLeadingRadius: AppRadius.r12)
                .fill(tint)
                .frame(width: AppSpacing.s4)
        }
        .appShadow(.large)
        .offset(y: max(0, dragOffset))
        .gesture(
            DragGesture()
                .onChanged { dragOffset = $0.translation.height }
                .onEnded { value in
                    if value.translation.height > AppSpacing.s40 {
                        onDismiss()
                    } else {
                        withAnimation(AppAnimation.fast) { dragOffset = 0 }
                    }
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape, onDismiss)
    }

    private var tint: Color {
        switch message.kind {
        case .success: AppColors.success
        case .error: AppColors.error
        case .warning: AppColors.warning
        case .info: AppColors.info
        }
    }

    private var icon: String {
        switch message.kind {
        case .success: "checkmark.circle.fill"
        case .error: "xmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }
}

/// Renders `FeedbackCenter.current`. Mounted once, in the overlay window (iOS) or as a root overlay.
public struct FeedbackHost: View {
    private let center: FeedbackCenter
    private let bottomInset: CGFloat
    private let onInteractiveFrameChange: (CGRect) -> Void

    /// `bottomInset`: keeps snackbars above the tab bar.
    public init(
        center: FeedbackCenter, bottomInset: CGFloat = AppSize.tabBarHeight,
        onInteractiveFrameChange: @escaping (CGRect) -> Void = { _ in }
    ) {
        self.center = center
        self.bottomInset = bottomInset
        self.onInteractiveFrameChange = onInteractiveFrameChange
    }

    public var body: some View {
        VStack {
            Spacer()
            if let message = center.current {
                Group {
                    switch message.style {
                    case .toast:
                        ToastView(message: message)
                    case .snackbar:
                        SnackBarView(message: message, onAction: center.performAction, onDismiss: center.dismiss)
                    }
                }
                .id(center.currentID)
                .padding(.horizontal, AppSpacing.s16)
                .padding(.bottom, bottomInset + AppSpacing.s8)
                .frame(maxWidth: AppSpacing.readableWidth)
                .onGeometryChange(for: CGRect.self) {
                    $0.frame(in: .global)
                } action: {
                    onInteractiveFrameChange($0)
                }
                .onDisappear { onInteractiveFrameChange(.zero) }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .animation(AppAnimation.spring, value: center.currentID)
        .sensoryFeedback(trigger: center.currentID) { _, _ in
            switch center.current?.kind {
            case .success: .success
            case .error: .error
            case .warning: .warning
            case .info, nil: nil
            }
        }
    }
}

#Preview("Toast and snackbars") {
    VStack(spacing: AppSpacing.s16) {
        ToastView(message: .toast("Added to wishlist"))
        SnackBarView(
            message: .success("Item removed", action: FeedbackAction(title: "Undo") {}), onAction: {}, onDismiss: {})
        SnackBarView(message: .error("Couldn't place the order. Please try again."), onAction: {}, onDismiss: {})
        SnackBarView(message: .warning("You're offline"), onAction: {}, onDismiss: {})
    }
    .padding(AppSpacing.s16)
    .frame(maxHeight: .infinity)
    .background(AppColors.background)
}

#Preview("Dark") {
    SnackBarView(message: .error("Something went wrong"), onAction: {}, onDismiss: {})
        .padding(AppSpacing.s16)
        .frame(maxHeight: .infinity)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
