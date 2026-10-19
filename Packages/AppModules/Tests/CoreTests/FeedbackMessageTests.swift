import Localization
import TestSupport
import Testing

@testable import Core

extension LanguageSensitive {
    @Suite("FeedbackMessage")
    @MainActor
    struct FeedbackMessageTests {
        init() { LocalizationBundle.apply(.en) }

        @Test("Toasts are short info; snackbars last longer, longer still with an action")
        func durations() {
            #expect(FeedbackMessage.toast("Saved").duration == .seconds(2))
            #expect(FeedbackMessage.success("Saved").duration == .seconds(4))
            #expect(
                FeedbackMessage.success("Removed", action: FeedbackAction(title: "Undo") {}).duration == .seconds(6))
        }

        @Test("Equality ignores the action closure but not its title")
        func equality() {
            let a = FeedbackMessage.error("Failed", action: FeedbackAction(title: "Retry") {})
            let b = FeedbackMessage.error("Failed", action: FeedbackAction(title: "Retry") {})
            #expect(a == b)
            #expect(a != FeedbackMessage.error("Failed"))
        }

        @Test("show(error:) uses the localized message and a Retry action")
        func showError() {
            let presenter = MockFeedbackPresenter()
            presenter.show(error: .timeout, retry: {})
            #expect(presenter.messages.first?.text == L10n.Error.timeout)
            #expect(presenter.messages.first?.action?.title == "Retry")
            #expect(presenter.messages.first?.kind == .error)
        }
    }
}
