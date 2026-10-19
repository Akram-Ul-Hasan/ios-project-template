#if canImport(UIKit)
    import UIKit
#endif

/// Lets a critical request finish (about 30 s) after the user leaves the app (§6n):
/// `try await runner.run("place-order") { try await placeOrder(input) }`.
/// If the system runs out of time, the operation is cancelled.
@MainActor
public struct BackgroundTaskRunner {
    public init() {}

    public func run<Value: Sendable>(
        _ name: String,
        operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let task = Task { try await operation() }
        #if canImport(UIKit)
            let id = UIApplication.shared.beginBackgroundTask(withName: name) { task.cancel() }
            defer { UIApplication.shared.endBackgroundTask(id) }
        #endif
        return try await task.value
    }
}
