import Core
import os

/// Lets `TokenRefresher` (created first, inside `AppContainer.init`) call the auth feature's refresh endpoint,
/// which is wired later by `AuthContainer`. Until then every refresh fails, which logs the user out.
final class TokenRefreshBridge: Sendable {
    private let handler = OSAllocatedUnfairLock<TokenRefresher.RefreshAction?>(initialState: nil)

    func setHandler(_ action: @escaping TokenRefresher.RefreshAction) {
        handler.withLock { $0 = action }
    }

    func refresh(_ refreshToken: String) async throws -> AuthTokens {
        guard let action = handler.withLock({ $0 }) else { throw ResponseError.unauthorized }
        return try await action(refreshToken)
    }
}
