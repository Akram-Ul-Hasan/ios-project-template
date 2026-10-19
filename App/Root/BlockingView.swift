import Core
import DesignSystem
import Localization
import SwiftUI

/// App-level blocking screens (§6o): maintenance (retry) and force update (App Store). No feature handles these.
struct BlockingView: View {
    let event: SessionEvent
    let onRetry: () -> Void
    @Environment(\.openURL) private var openURL

    /// Replace with the app's App Store id.
    private static let appStoreURL = URL(string: "https://apps.apple.com/app/id0000000000")

    var body: some View {
        Group {
            switch event {
            case .updateRequired:
                EmptyStateView(
                    systemImage: "arrow.down.app", title: L10n.Blocking.updateTitle, message: L10n.Error.updateRequired,
                    actionTitle: L10n.Blocking.updateAction
                ) {
                    if let url = Self.appStoreURL { openURL(url) }
                }
            default:
                EmptyStateView(
                    systemImage: "wrench.and.screwdriver", title: L10n.Blocking.maintenanceTitle,
                    message: L10n.Error.maintenance, actionTitle: L10n.Common.retry, action: onRetry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}
