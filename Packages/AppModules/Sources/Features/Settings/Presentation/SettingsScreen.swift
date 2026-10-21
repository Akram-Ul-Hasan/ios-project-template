import Core
import DesignSystem
import Localization
import SwiftUI

public struct SettingsScreen: View {
    @State private var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Form {
            Section(L10n.Settings.appearance) {
                LanguagePicker(manager: viewModel.localization)
                ThemePicker(manager: viewModel.theme)
            }
            Section(L10n.Settings.account) {
                Button(L10n.Account.logout, role: .destructive) {
                    viewModel.confirmLogout(
                        title: L10n.Settings.logoutConfirmTitle, message: L10n.Settings.logoutConfirmMessage,
                        confirm: L10n.Account.logout, cancel: L10n.Common.cancel)
                }
            }
            Section {
            } footer: {
                Text(L10n.Settings.version(viewModel.version.marketing, viewModel.version.build))
                    .frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .commonAppBar(L10n.Route.settings)
        .confirmDialog(item: $viewModel.logoutDialog)
    }
}
