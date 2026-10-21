import Core
import __Feature__Data
import __Feature__Domain
import __Feature__Presentation

/// __Feature__ wiring (§6). Add `let __featureCamel__: __Feature__Container` to `AppContainer` and create it in `init`.
@MainActor
final class __Feature__Container {
    let repository: any __Feature__Repository
    private let errorHandler: ErrorHandler

    init(env: Env, client: any HTTPClient, mockData: MockDataHelper, errorHandler: ErrorHandler) {
        let factory: any __Feature__DataSourceFactory =
            env.environment == .development
            ? __Feature__MockDataSourceFactory(mock: mockData)
            : __Feature__RemoteDataSourceFactory(client: client)
        repository = __Feature__RepositoryImpl(factory: factory)
        self.errorHandler = errorHandler
    }

    var getItemsUseCase: Get__Feature__ItemsUseCase { Get__Feature__ItemsUseCase(repository: repository) }

    func makeListViewModel(onItemTap: @escaping @MainActor (String) -> Void) -> __Feature__ListViewModel {
        __Feature__ListViewModel(getItems: getItemsUseCase, errorHandler: errorHandler, onItemTap: onItemTap)
    }
}
