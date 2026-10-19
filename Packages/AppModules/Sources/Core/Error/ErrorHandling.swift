import SharedDomain

/// What a view model needs to apply `ErrorPolicy`. Built once by `AppContainer`, passed to every view model.
@MainActor
public struct ErrorHandler {
    public let feedback: any FeedbackPresenting
    public let events: SessionEvents

    public init(feedback: any FeedbackPresenting, events: SessionEvents) {
        self.feedback = feedback
        self.events = events
    }
}

/// Gives view models a one-line `catch` (rule 36):
/// `catch { handle(error, context: .action, form: form, retry: { Task { await self.submit() } }) }`.
@MainActor
public protocol ErrorHandling: AnyObject {
    var errorHandler: ErrorHandler { get }
    /// Full-screen treatments: typically `state = .failure(error)`.
    func showFailure(_ error: ResponseError)
    /// Business-rule errors. Defaults to an error snackbar; override to show a `ConfirmDialog`.
    func showDialog(for error: ResponseError)
}

extension ErrorHandling {
    public func showDialog(for error: ResponseError) {
        errorHandler.feedback.show(error: error)
    }

    public func handle(
        _ error: any Error,
        context: ErrorContext,
        form: FormState? = nil,
        retry: (@MainActor @Sendable () -> Void)? = nil
    ) {
        let error = ResponseError.from(error)
        ErrorPolicy.log(error, context: context)
        switch ErrorPolicy.treatment(for: error, context: context) {
        case .silent, .listRetry:
            break
        case .fullScreen, .offline:
            showFailure(error)
        case .snackbar(let retryable):
            errorHandler.feedback.show(error: error, retry: retryable ? retry : nil)
        case .inline:
            applyInline(error, form: form)
        case .dialog:
            showDialog(for: error)
        case .forceLogout:
            // RootView's logout must be idempotent: TokenRefresher may already have sent this.
            errorHandler.events.send(.sessionExpired)
            errorHandler.feedback.show(.warning(error.localizedMessage))
        case .blocking(let event):
            errorHandler.events.send(event)
        }
    }

    private func applyInline(_ error: ResponseError, form: FormState?) {
        switch error {
        case .validation(let message, let fieldErrors):
            let unmatched = form?.applyServerErrors(fieldErrors) ?? fieldErrors.values.compactMap(\.first)
            // The general message (or messages for fields the form doesn't have) goes to a snackbar.
            let text = [message].compactMap { $0 }.filter { !$0.isEmpty } + unmatched
            errorHandler.feedback.show(.error(text.isEmpty ? error.localizedMessage : text.joined(separator: "\n")))
        case .domain(.validation(let field, let validation)):
            let unmatched =
                form?.applyServerErrors([field: [validation.localizedMessage]]) ?? [validation.localizedMessage]
            if !unmatched.isEmpty { errorHandler.feedback.show(.error(unmatched.joined(separator: "\n"))) }
        default:
            errorHandler.feedback.show(error: error)
        }
    }
}
