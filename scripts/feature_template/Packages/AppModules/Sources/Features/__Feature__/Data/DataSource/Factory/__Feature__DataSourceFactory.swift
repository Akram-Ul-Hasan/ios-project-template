import Core

public protocol __Feature__DataSourceFactory: Sendable {
    func makeDataSource() -> any __Feature__DataSource
}

public struct __Feature__MockDataSourceFactory: __Feature__DataSourceFactory {
    private let mock: MockDataHelper

    public init(mock: MockDataHelper) {
        self.mock = mock
    }

    public func makeDataSource() -> any __Feature__DataSource {
        __Feature__MockDataSource(mock: mock)
    }
}

public struct __Feature__RemoteDataSourceFactory: __Feature__DataSourceFactory {
    private let client: any HTTPClient

    public init(client: any HTTPClient) {
        self.client = client
    }

    public func makeDataSource() -> any __Feature__DataSource {
        __Feature__RemoteDataSource(client: client)
    }
}
