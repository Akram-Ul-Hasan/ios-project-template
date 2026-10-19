import os

/// Named intervals that show up in Instruments (Points of Interest) — screen loads, image decodes, mapping.
public enum Signposts {
    public static let signposter = OSSignposter(subsystem: AppLogger.subsystem, category: .pointsOfInterest)

    /// Measures `work` as one interval: `try await Signposts.interval("HomeFeed") { try await load() }`.
    public static func interval<T>(
        _ name: StaticString,
        _ work: () async throws -> T
    ) async rethrows -> T {
        let state = signposter.beginInterval(name, id: signposter.makeSignpostID())
        defer { signposter.endInterval(name, state) }
        return try await work()
    }
}
