import AuthData
import Core
import Testing

/// Fixtures decode through the same DTOs and mappers as real responses, so a broken fixture fails here (§3a).
/// Runs in the Development test host, the only build that contains `*.mock.json`.
@Suite("Mock fixtures")
@MainActor
struct MockFixtureTests {
    private let mock = MockDataHelper(latency: .zero)

    @Test("Auth fixtures decode and map")
    func auth() async throws {
        let source = AuthMockDataSource(mock: mock)
        let login = try await source.login(LoginRequest(phone: "01712345678", password: "secret"))
        _ = try login.toEntities()
        _ = try await source.refresh(RefreshRequest(refreshToken: "r")).toEntity()
        await #expect(throws: ResponseError.self) {
            try await source.login(LoginRequest(phone: "01712345678", password: "wrong"))
        }
    }
}
