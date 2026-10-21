import Core

public protocol CatalogDataSourceFactory: Sendable {
    func makeCatalogDataSource() -> any CatalogDataSource
}

public struct CatalogMockDataSourceFactory: CatalogDataSourceFactory {
    private let mock: MockDataHelper

    public init(mock: MockDataHelper) {
        self.mock = mock
    }

    public func makeCatalogDataSource() -> any CatalogDataSource {
        CatalogMockDataSource(mock: mock)
    }
}

public struct CatalogRemoteDataSourceFactory: CatalogDataSourceFactory {
    private let client: any HTTPClient

    public init(client: any HTTPClient) {
        self.client = client
    }

    public func makeCatalogDataSource() -> any CatalogDataSource {
        CatalogRemoteDataSource(client: client)
    }
}
