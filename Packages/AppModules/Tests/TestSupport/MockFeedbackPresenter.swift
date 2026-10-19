import Core

/// Records every message a view model shows.
@MainActor
public final class MockFeedbackPresenter: FeedbackPresenting {
    public private(set) var messages: [FeedbackMessage] = []

    public init() {}

    public func show(_ message: FeedbackMessage) {
        messages.append(message)
    }
}
