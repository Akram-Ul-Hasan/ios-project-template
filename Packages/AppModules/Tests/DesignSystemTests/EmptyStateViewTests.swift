import Core
import Localization
import Testing

@testable import DesignSystem

@Suite("EmptyStateView", .serialized)
@MainActor
struct EmptyStateViewTests {
    init() { LocalizationBundle.apply(.en) }

    @Test("Network errors look like offline; others like a generic failure")
    func appearance() {
        #expect(EmptyStateView.appearance(for: .network) == ("wifi.slash", L10n.State.offlineTitle))
        #expect(EmptyStateView.appearance(for: .notFound).systemImage == "magnifyingglass")
        #expect(
            EmptyStateView.appearance(for: .server(statusCode: 500)) == ("exclamationmark.triangle", L10n.Error.title))
    }
}
