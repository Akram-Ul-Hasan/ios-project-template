import AuthDomain
import Core
import DesignSystem
import Localization
import SwiftUI

/// One adaptive layout from the portrait design (§2a): a readable-width column that works on every device.
public struct LoginScreen: View {
    @State private var viewModel: LoginViewModel

    public init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.s24) {
                VStack(alignment: .leading, spacing: AppSpacing.s8) {
                    Text(L10n.Login.title)
                        .font(AppTypography.title1)
                        .foregroundStyle(AppColors.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(L10n.Login.subtitle)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
                VStack(spacing: AppSpacing.s16) {
                    AppTextField(
                        L10n.Login.phone, placeholder: L10n.Login.phonePlaceholder, field: viewModel.phone,
                        keyboard: .phone)
                    AppSecureField(L10n.Login.password, field: viewModel.password)
                }
                PrimaryButton(L10n.Login.submit, isLoading: viewModel.isSubmitting) {
                    Task { await viewModel.submit() }
                }
                .disabled(!viewModel.form.isValid)
            }
            .padding(AppSpacing.s24)
            .frame(maxWidth: AppSpacing.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.background)
        .confirmDialog(item: $viewModel.dialog)
    }
}

#if DEBUG
    private struct PreviewAuthRepository: AuthRepository {
        func login(_ input: LoginInputEntity) async throws -> UserEntity {
            try await Task.sleep(for: .seconds(1))
            return UserEntity(id: "1", name: "Preview", phone: input.phone, email: nil, avatarURL: nil)
        }
        func logout() async throws {}
        func refresh(refreshToken: String) async throws -> AuthTokensEntity {
            AuthTokensEntity(accessToken: "", refreshToken: "")
        }
    }

    @MainActor
    private func previewViewModel() -> LoginViewModel {
        LoginViewModel(
            login: LoginUseCase(repository: PreviewAuthRepository()),
            errorHandler: ErrorHandler(feedback: FeedbackCenter(), events: SessionEvents()),
            network: .preview(isOnline: true), onLoggedIn: { _ in })
    }

    #Preview("Login") {
        LoginScreen(viewModel: previewViewModel())
    }

    #Preview("Matrix") {
        PreviewMatrix { LoginScreen(viewModel: previewViewModel()) }
    }
#endif
