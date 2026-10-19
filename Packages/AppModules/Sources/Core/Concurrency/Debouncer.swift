/// Runs only the last call after a quiet period (search as you type).
/// In views, `.task(id: query) { try? await Task.sleep(for: …) }` does the same with no object at all.
@MainActor
public final class Debouncer {
    private let delay: Duration
    private var task: Task<Void, Never>?

    public init(delay: Duration) {
        self.delay = delay
    }

    public func call(_ action: @escaping @MainActor () async -> Void) {
        task?.cancel()
        task = Task { [delay] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return  // cancelled by a newer call
            }
            await action()
        }
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }
}

/// Runs the first call, then ignores calls for `interval` (button spam, repeated pull-to-refresh).
@MainActor
public final class Throttler {
    private let interval: Duration
    private var lastRun: ContinuousClock.Instant?

    public init(interval: Duration) {
        self.interval = interval
    }

    public func call(at now: ContinuousClock.Instant = .now, _ action: @MainActor () -> Void) {
        if let lastRun, lastRun.duration(to: now) < interval { return }
        lastRun = now
        action()
    }
}
