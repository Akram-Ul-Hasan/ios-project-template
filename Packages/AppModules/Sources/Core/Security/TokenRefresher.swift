/// Refreshes the session once, however many requests hit a 401 at the same time (§6l).
/// If the refresh token is rejected the session is over: tokens are cleared and `.sessionExpired` is published.
public actor TokenRefresher {
    public typealias RefreshAction = @Sendable (_ refreshToken: String) async throws -> AuthTokens

    private let store: any TokenStore
    private let events: SessionEvents
    private let refreshAction: RefreshAction
    private var inFlight: Task<AuthTokens, any Error>?

    /// `refreshAction` calls the backend's refresh endpoint (wired by the auth feature's container).
    public init(store: any TokenStore, events: SessionEvents, refreshAction: @escaping RefreshAction) {
        self.store = store
        self.events = events
        self.refreshAction = refreshAction
    }

    public func refresh() async throws -> AuthTokens {
        if let inFlight { return try await inFlight.value }
        guard let current = store.tokens() else {
            expire()
            throw ResponseError.unauthorized
        }
        let task = Task { [refreshAction] in try await refreshAction(current.refreshToken) }
        inFlight = task
        defer { inFlight = nil }
        do {
            let tokens = try await task.value
            try store.save(tokens)
            return tokens
        } catch {
            let mapped = ResponseError.from(error)
            switch mapped {
            // Offline or slow: the session may still be valid, so don't log the user out.
            case .network, .timeout, .cancelled: throw mapped
            default:
                expire()
                throw ResponseError.unauthorized
            }
        }
    }

    private func expire() {
        AppLogger.auth.notice("session expired, logging out")
        try? store.clear()
        events.send(.sessionExpired)
    }
}
