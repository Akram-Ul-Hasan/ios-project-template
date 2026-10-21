import Core
import DesignSystem
import Localization
import SwiftUI

public struct SettingsScreen: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.scenePhase) private var scenePhase

    public init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Form {
            Section(L10n.Settings.appearance) {
                LanguagePicker(manager: viewModel.localization)
                ThemePicker(manager: viewModel.theme)
            }
            Section {
                ForEach(AppPermission.allCases, id: \.self) { permission in
                    LabeledContent {
                        Text(viewModel.permissionStatuses[permission]?.title ?? "")
                            .foregroundStyle(AppColors.textSecondary)
                    } label: {
                        Label(permission.title, systemImage: permission.systemImage)
                    }
                }
            } header: {
                Text(L10n.Settings.permissions)
            } footer: {
                AppTextButton(L10n.Common.openSettings, action: viewModel.openAppSettings)
            }
            if viewModel.isDiagnosticsEnabled {
                Section(L10n.Settings.diagnostics) {
                    Button {
                        Task { await viewModel.exportLogs() }
                    } label: {
                        LabeledContent(L10n.Settings.exportLogs) {
                            if viewModel.isExportingLogs { ProgressView() }
                        }
                    }
                    .disabled(viewModel.isExportingLogs)
                    if let logs = viewModel.exportedLogs {
                        ShareLink(item: logs) { Label(L10n.Settings.shareLogs, systemImage: "square.and.arrow.up") }
                    }
                }
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
        .task { await viewModel.loadPermissions() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await viewModel.loadPermissions() } }
        }
    }
}
