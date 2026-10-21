import AuthDomain
import AuthPresentation
import Core
import Localization
import TestSupport
import Testing

@Suite("LoginViewModel", .serialized)
@MainActor
struct LoginViewModelTests {
    private final class Repository: AuthRepository {
        let result: Result<UserEntity, any Error>
        init(_ result: Result<UserEntity, any Error>) { self.result = result }
        func login(_ input: LoginInputEntity) async throws -> UserEntity { try result.get() }
        func logout() async throws {}
        func refresh(refreshToken: String) async throws -> AuthTokensEntity {
            AuthTokensEntity(accessToken: "", refreshToken: "")
        }
    }

    private static let user = UserEntity(id: "u1", name: "Rahim", phone: "01712345678", email: nil, avatarURL: nil)
    private let feedback = MockFeedbackPresenter()

    init() { LocalizationBundle.apply(.en) }

    private func makeViewModel(
        _ result: Result<UserEntity, any Error> = .success(user),
        online: Bool = true,
        onLoggedIn: @escaping @MainActor (UserEntity) -> Void = { _ in }
    ) -> LoginViewModel {
        LoginViewModel(
            login: LoginUseCase(repository: Repository(result)),
            errorHandler: ErrorHandler(feedback: feedback, events: SessionEvents()),
            network: NetworkMonitor.preview(isOnline: online),
            onLoggedIn: onLoggedIn)
    }

    @Test("Invalid input shows field errors and never calls the backend")
    func invalidInput() async {
        var signedIn = false
        let model = makeViewModel { _ in signedIn = true }
        model.phone.value = "123"
        await model.submit()
        #expect(model.phone.error == .invalidFormat(.phone))
        #expect(model.password.error == .required)
        #expect(!signedIn)
    }

    @Test("Valid input signs in")
    func success() async {
        var signedInUser: UserEntity?
        let model = makeViewModel { signedInUser = $0 }
        model.phone.value = "01712345678"
        model.password.value = "secret"
        await model.submit()
        #expect(signedInUser == Self.user)
        #expect(!model.isSubmitting)
    }

    @Test("Offline: instant feedback, no request")
    func offline() async {
        let model = makeViewModel(online: false)
        model.phone.value = "01712345678"
        model.password.value = "secret"
        await model.submit()
        #expect(feedback.messages.first?.text == L10n.Error.network)
    }

    @Test("A 422 lands under the password field")
    func serverValidation() async {
        let error = ResponseError.validation(message: nil, fieldErrors: ["password": ["Wrong password"]])
        let model = makeViewModel(.failure(error))
        model.phone.value = "01712345678"
        model.password.value = "nope"
        await model.submit()
        #expect(model.password.errorMessage == "Wrong password")
    }

    @Test("Business errors open a dialog")
    func businessError() async {
        let model = makeViewModel(.failure(ResponseError.business(code: nil, message: "Account locked")))
        model.phone.value = "01712345678"
        model.password.value = "secret"
        await model.submit()
        #expect(model.dialog?.message == "Account locked")
    }
}
