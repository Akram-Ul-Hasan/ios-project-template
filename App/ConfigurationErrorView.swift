import DesignSystem
import Localization
import SwiftUI

/// Shown only when Info.plist lacks the flavor values (a broken build), instead of crashing at launch.
struct ConfigurationErrorView: View {
    var body: some View {
        EmptyStateView(systemImage: "wrench.and.screwdriver", title: L10n.Error.title, message: L10n.Error.generic)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
    }
}
