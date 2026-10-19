import Localization
import SharedDomain
import TestSupport
import Testing

@testable import Core

extension LanguageSensitive {
    @Suite("ErrorHandling")
    @MainActor
    struct ErrorHandlingTests {
        @MainActor
        final class ViewModel: ErrorHandling {
            let errorHandler: ErrorHandler
            var state: ViewState<Int> = .idle
            var dialogs: [ResponseError] = []
            init(_ handler: ErrorHandler) { errorHandler = handler }
            func showFailure(_ error: ResponseError) { state = .failure(error) }
            func showDialog(for error: ResponseError) { dialogs.append(error) }
        }

        private let feedback = MockFeedbackPresenter()
        private let events = SessionEvents()
        private var viewModel: ViewModel { ViewModel(ErrorHandler(feedback: feedback, events: events)) }

        init() { LocalizationBundle.apply(.en) }

        @Test("Initial load failures become the screen state")
        func initialLoad() {
            let model = viewModel
            model.handle(ResponseError.timeout, context: .initialLoad)
            #expect(model.state == .failure(.timeout))
            #expect(feedback.messages.isEmpty)
        }

        @Test("Refresh failures are snackbars with Retry; the state is untouched")
        func refresh() {
            let model = viewModel
            model.state = .success(1)
            model.handle(ResponseError.network, context: .refresh, retry: {})
            #expect(model.state == .success(1))
            #expect(feedback.messages.first?.action?.title == L10n.Common.retry)
        }

        @Test("422 errors land on the form; the general message goes to a snackbar")
        func validation() {
            let phone = FormField(name: "phone", "01712345678", rules: [Rules.phoneBD])
            let form = FormState(phone)
            viewModel.handle(
                ResponseError.validation(message: "Check the form", fieldErrors: ["phone": ["Taken"]]),
                context: .action,
                form: form)
            #expect(phone.errorMessage == "Taken")
            #expect(feedback.messages.map(\.text) == ["Check the form"])
        }

        @Test("Domain validation from a use case lands on the field")
        func domainValidation() {
            let phone = FormField(name: "phone", "", rules: [])
            viewModel.handle(
                DomainError.validation(field: "phone", error: .required), context: .action, form: FormState(phone))
            #expect(phone.errorMessage == L10n.Validation.required)
            #expect(feedback.messages.isEmpty)
        }

        @Test("Business errors open the dialog")
        func business() {
            let model = viewModel
            model.handle(ResponseError.business(code: .outOfStock, message: nil), context: .action)
            #expect(model.dialogs == [.business(code: .outOfStock, message: nil)])
        }

        @Test("401 forces logout; maintenance blocks the app; cancellation is silent")
        func appLevel() async {
            var iterator = events.stream().makeAsyncIterator()
            let model = viewModel
            model.handle(ResponseError.unauthorized, context: .action)
            model.handle(ResponseError.maintenance, context: .initialLoad)
            model.handle(CancellationError(), context: .initialLoad)
            #expect(await iterator.next() == .sessionExpired)
            #expect(await iterator.next() == .maintenance)
            #expect(model.state == .idle)
        }
    }
}
