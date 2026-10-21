import Core
import SharedDomain
import TestSupport
import Testing
import __Feature__Domain
import __Feature__Presentation

@Suite("__Feature__ListViewModel")
@MainActor
struct __Feature__ListViewModelTests {
    private struct Repository: __Feature__Repository {
        func items(_ pagination: PaginationInputEntity) async throws -> PaginatedEntity<__Feature__ItemEntity> {
            PaginatedEntity(items: [__Feature__ItemEntity(id: "1", title: "First")], page: 1, hasNext: false)
        }
    }

    @Test("Loads items and reports taps")
    func loadAndTap() async {
        var tapped: String?
        let model = __Feature__ListViewModel(
            getItems: Get__Feature__ItemsUseCase(repository: Repository()),
            errorHandler: ErrorHandler(feedback: MockFeedbackPresenter(), events: SessionEvents())
        ) { tapped = $0 }
        await model.items.loadFirst()
        #expect(model.items.items.count == 1)
        model.select(model.items.items[0])
        #expect(tapped == "1")
    }
}
