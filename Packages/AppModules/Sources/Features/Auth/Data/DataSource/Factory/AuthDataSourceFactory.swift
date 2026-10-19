import Core

/// Abstract factory (§11): the repository only sees this, never which source is behind it.
public protocol AuthDataSourceFactory: Sendable {
    func makeAuthDataSource() -> any AuthDataSource
}

/// Development: JSON fixtures, no network.
public struct AuthMockDataSourceFactory: AuthDataSourceFactory {
    private let mock: MockDataHelper

    public init(mock: MockDataHelper) {
        self.mock = mock
    }

    public func makeAuthDataSource() -> any AuthDataSource {
        AuthMockDataSource(mock: mock)
    }
}

/// Staging and production: the real API.
public struct AuthRemoteDataSourceFactory: AuthDataSourceFactory {
    private let unauthenticatedClient: any HTTPClient
    private let authenticatedClient: any HTTPClient

    public init(unauthenticatedClient: any HTTPClient, authenticatedClient: any HTTPClient) {
        self.unauthenticatedClient = unauthenticatedClient
        self.authenticatedClient = authenticatedClient
    }

    public func makeAuthDataSource() -> any AuthDataSource {
        AuthRemoteDataSource(unauthenticatedClient: unauthenticatedClient, authenticatedClient: authenticatedClient)
    }
}
