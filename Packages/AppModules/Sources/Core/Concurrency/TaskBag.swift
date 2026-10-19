import Foundation
import os

/// Owns long-running tasks of an object and cancels them all when the object goes away (§6n):
/// `@ObservationIgnored private let tasks = TaskBag()`, then `tasks.add(Task { [weak self] in … })`.
/// Prefer starting long work from the view with `.task { }`; use this only when the object must own it.
public final class TaskBag: Sendable {
    private let tasks = OSAllocatedUnfairLock<[Task<Void, Never>]>(initialState: [])

    public init() {}

    public func add(_ task: Task<Void, Never>) {
        tasks.withLock { $0.append(task) }
    }

    public func cancelAll() {
        let current = tasks.withLock { tasks in
            defer { tasks.removeAll() }
            return tasks
        }
        for task in current {
            task.cancel()
        }
    }

    deinit {
        cancelAll()
    }
}
