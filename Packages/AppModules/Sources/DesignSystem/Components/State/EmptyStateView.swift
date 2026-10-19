import Core
import Localization
import SwiftUI

/// Every empty and error state in the app (rule 7): icon, title, optional message and action.
/// For errors use `EmptyStateView(error:retry:)` so the text always comes from `ResponseError.localizedMessage`.
public struct EmptyStateView: View {
    private let systemImage: String
    private let title: String
    private let message: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        systemImage: String = "tray",
        title: String = L10n.State.emptyTitle,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    /// Error state: offline icon and title for network errors, Retry when `retry` is given.
    public init(error: ResponseError, retry: (() -> Void)?) {
        let appearance = Self.appearance(for: error)
        self.init(
            systemImage: appearance.systemImage, title: appearance.title, message: error.localizedMessage,
            actionTitle: retry == nil ? nil : L10n.Common.retry, action: retry)
    }

    public var body: some View {
        VStack(spacing: AppSpacing.s16) {
            Image(systemName: systemImage)
                .font(.system(size: AppIconSize.s48, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
                .accessibilityHidden(true)
            VStack(spacing: AppSpacing.s8) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                if let message {
                    Text(message)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
            if let actionTitle, let action {
                SecondaryButton(actionTitle, action: action)
                    .fixedSize()
                    .padding(.top, AppSpacing.s8)
            }
        }
        .padding(AppSpacing.s24)
        .frame(maxWidth: AppSpacing.readableWidth)
        .accessibilityElement(children: .contain)
    }

    static func appearance(for error: ResponseError) -> (systemImage: String, title: String) {
        switch error {
        case .network: ("wifi.slash", L10n.State.offlineTitle)
        case .notFound: ("magnifyingglass", L10n.Error.notFound)
        default: ("exclamationmark.triangle", L10n.Error.title)
        }
    }
}

#Preview("Empty and error") {
    VStack(spacing: AppSpacing.s40) {
        EmptyStateView(systemImage: "cart", title: "Your cart is empty", message: "Add something you like.")
        EmptyStateView(error: .network, retry: {})
    }
}

#Preview("Dark") {
    EmptyStateView(error: .server(statusCode: 500), retry: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
