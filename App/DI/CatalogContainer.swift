import CatalogData
import CatalogDomain
import CatalogPresentation
import Core

/// Catalog wiring: mock or remote source → repository → cache decorator (composed explicitly, §11).
@MainActor
final class CatalogContainer {
    let repository: any CatalogRepository
    private let errorHandler: ErrorHandler

    init(
        env: Env, client: any HTTPClient, mockData: MockDataHelper, persistence: PersistenceController,
        errorHandler: ErrorHandler
    ) {
        let factory: any CatalogDataSourceFactory =
            env.environment == .development
            ? CatalogMockDataSourceFactory(mock: mockData)
            : CatalogRemoteDataSourceFactory(client: client)
        repository = CatalogCacheRepository(
            remote: CatalogRepositoryImpl(factory: factory), local: CatalogLocalDataSource(persistence: persistence))
        self.errorHandler = errorHandler
    }

    var getProductsUseCase: GetProductsUseCase { GetProductsUseCase(repository: repository) }
    var getProductDetailsUseCase: GetProductDetailsUseCase { GetProductDetailsUseCase(repository: repository) }

    func makeProductListViewModel(onProductTap: @escaping @MainActor (String) -> Void) -> ProductListViewModel {
        ProductListViewModel(getProducts: getProductsUseCase, errorHandler: errorHandler, onProductTap: onProductTap)
    }

    func makeProductDetailsViewModel(id: String) -> ProductDetailsViewModel {
        ProductDetailsViewModel(productID: id, getDetails: getProductDetailsUseCase, errorHandler: errorHandler)
    }
}
