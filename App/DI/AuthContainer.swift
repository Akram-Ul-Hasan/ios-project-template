import AuthData
import AuthDomain
import AuthPresentation
import Core

/// Auth wiring (§6): data source factory → repository (one per app) → use cases and view models (new each time).
@MainActor
final class AuthContainer {
    let repository: any AuthRepository
    private let errorHandler: ErrorHandler
    private let network: NetworkMonitor

    init(
        env: Env,
        unauthenticatedClient: any HTTPClient,
        authenticatedClient: any HTTPClient,
        tokenStore: any TokenStore,
        mockData: MockDataHelper,
        errorHandler: ErrorHandler,
        network: NetworkMonitor
    ) {
        let factory: any AuthDataSourceFactory =
            env.environment == .development
            ? AuthMockDataSourceFactory(mock: mockData)
            : AuthRemoteDataSourceFactory(
                unauthenticatedClient: unauthenticatedClient, authenticatedClient: authenticatedClient)
        repository = AuthRepositoryImpl(factory: factory, tokenStore: tokenStore)
        self.errorHandler = errorHandler
        self.network = network
    }

    var loginUseCase: LoginUseCase { LoginUseCase(repository: repository) }
    var logoutUseCase: LogoutUseCase { LogoutUseCase(repository: repository) }
    var refreshSessionUseCase: RefreshSessionUseCase { RefreshSessionUseCase(repository: repository) }

    func makeLoginViewModel(onLoggedIn: @escaping @MainActor (UserEntity) -> Void) -> LoginViewModel {
        LoginViewModel(login: loginUseCase, errorHandler: errorHandler, network: network, onLoggedIn: onLoggedIn)
    }
}
