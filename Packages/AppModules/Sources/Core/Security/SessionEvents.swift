import Foundation
import os

/// App-level events no feature handles itself; `RootView` reacts (log out, blocking screen).
public enum SessionEvent: Equatable, Sendable {
    case sessionExpired
    case loggedOut
    case maintenance
    case updateRequired
}

/// Broadcasts `SessionEvent`s to every subscriber. One instance, created by `AppContainer`.
public final class SessionEvents: Sendable {
    private let continuations = OSAllocatedUnfairLock<[UUID: AsyncStream<SessionEvent>.Continuation]>(initialState: [:])

    public init() {}

    public func send(_ event: SessionEvent) {
        let targets = continuations.withLock { Array($0.values) }
        for continuation in targets {
            continuation.yield(event)
        }
    }

    /// Events sent after subscribing. Ends when the consuming task is cancelled.
    public func stream() -> AsyncStream<SessionEvent> {
        AsyncStream { continuation in
            let id = UUID()
            continuations.withLock { $0[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.continuations.withLock { $0[id] = nil }
            }
        }
    }
}
