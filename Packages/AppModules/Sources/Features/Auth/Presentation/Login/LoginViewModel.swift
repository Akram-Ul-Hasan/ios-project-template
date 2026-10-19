import AuthDomain
import Core
import DesignSystem
import Observation
import SharedDomain
import os

@MainActor
@Observable
public final class LoginViewModel: ErrorHandling {
    public let phone = FormField(name: LoginUseCase.Field.phone, "", rules: [Rules.required, Rules.phoneBD])
    public let password = FormField(name: LoginUseCase.Field.password, "", rules: [Rules.required])
    public private(set) var isSubmitting = false
    public var dialog: DialogModel?

    @ObservationIgnored public let form: FormState
    @ObservationIgnored public let errorHandler: ErrorHandler
    @ObservationIgnored private let login: LoginUseCase
    @ObservationIgnored private let network: NetworkMonitor
    @ObservationIgnored private let onLoggedIn: @MainActor (UserEntity) -> Void

    /// `onLoggedIn`: the app moves to the signed-in shell; the screen itself knows nothing about navigation.
    public init(
        login: LoginUseCase,
        errorHandler: ErrorHandler,
        network: NetworkMonitor,
        onLoggedIn: @escaping @MainActor (UserEntity) -> Void
    ) {
        self.login = login
        self.errorHandler = errorHandler
        self.network = network
        self.onLoggedIn = onLoggedIn
        form = FormState(phone, password)
    }

    public func submit() async {
        guard !isSubmitting, form.validateAll() else { return }
        // Instant feedback instead of waiting for a timeout (§6m level 3).
        guard network.isOnline else {
            errorHandler.feedback.show(.offline)
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let user = try await login(LoginInputEntity(phone: phone.value, password: password.value))
            onLoggedIn(user)
        } catch {
            handle(error, context: .action, form: form)
        }
    }

    public func showFailure(_ error: ResponseError) {
        errorHandler.feedback.show(error: error)
    }

    public func showDialog(for error: ResponseError) {
        dialog = DialogModel(error: error)
    }

    #if DEBUG
        deinit { AppLogger.lifecycle.debug("deinit LoginViewModel") }
    #endif
}
