import Testing

@testable import Core

@Suite("Concurrency utilities")
@MainActor
struct ConcurrencyTests {
    @Test("TaskBag cancels everything on cancelAll and on deinit")
    func taskBag() async {
        let first = Task<Void, Never> { try? await Task.sleep(for: .seconds(10)) }
        let second = Task<Void, Never> { try? await Task.sleep(for: .seconds(10)) }
        var bag: TaskBag? = TaskBag()
        bag?.add(first)
        bag?.cancelAll()
        #expect(first.isCancelled)

        bag?.add(second)
        bag = nil
        #expect(second.isCancelled)
    }

    @Test("Debouncer runs only the last call")
    func debouncer() async throws {
        var runs: [Int] = []
        let debouncer = Debouncer(delay: .milliseconds(30))
        for value in 1...3 {
            debouncer.call { runs.append(value) }
        }
        try await Task.sleep(for: .milliseconds(150))
        #expect(runs == [3])
    }

    @Test("Throttler ignores calls inside the interval")
    func throttler() {
        var runs = 0
        let throttler = Throttler(interval: .seconds(1))
        let start = ContinuousClock.now
        throttler.call(at: start) { runs += 1 }
        throttler.call(at: start + .milliseconds(500)) { runs += 1 }
        throttler.call(at: start + .seconds(2)) { runs += 1 }
        #expect(runs == 2)
    }
}
