import Foundation

/// Infra numbers for networking (§6o). Fail fast and clearly instead of waiting for connectivity.
public enum NetworkConstants {
    public static let requestTimeout: TimeInterval = 15
    public static let resourceTimeout: TimeInterval = 60
    /// Extra attempts after a recoverable failure, e.g. one retry after a token refresh.
    public static let maxRetryCount = 1
    public static let defaultPageSize = 20
    /// Simulated latency of mock data sources, so loading states are visible in development.
    public static let mockLatency: Duration = .milliseconds(400)
}
