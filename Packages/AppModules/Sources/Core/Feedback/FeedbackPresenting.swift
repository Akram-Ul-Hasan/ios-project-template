import Foundation
import Localization

/// Toast = short neutral info; snackbar = a result that may need an action (§6m).
public enum FeedbackStyle: Sendable {
    case toast
    case snackbar
}

public enum FeedbackKind: Sendable {
    case success
    case error
    case warning
    case info
}

/// The single button a snackbar may have ("Undo", "Retry").
public struct FeedbackAction: Sendable {
    public let title: String
    public let handler: @MainActor @Sendable () -> Void

    public init(title: String, handler: @escaping @MainActor @Sendable () -> Void) {
        self.title = title
        self.handler = handler
    }
}

public struct FeedbackMessage: Sendable {
    public let style: FeedbackStyle
    public let kind: FeedbackKind
    /// Already localized (`L10n`).
    public let text: String
    public let action: FeedbackAction?
    public let duration: Duration

    public init(style: FeedbackStyle, kind: FeedbackKind, text: String, action: FeedbackAction?, duration: Duration) {
        self.style = style
        self.kind = kind
        self.text = text
        self.action = action
        self.duration = duration
    }

    private static let toastDuration: Duration = .seconds(2)
    private static let snackbarDuration: Duration = .seconds(4)
    private static let actionSnackbarDuration: Duration = .seconds(6)

    public static func toast(_ text: String) -> Self {
        Self(style: .toast, kind: .info, text: text, action: nil, duration: toastDuration)
    }

    public static func snackbar(_ kind: FeedbackKind, _ text: String, action: FeedbackAction? = nil) -> Self {
        Self(
            style: .snackbar, kind: kind, text: text, action: action,
            duration: action == nil ? snackbarDuration : actionSnackbarDuration)
    }

    public static func success(_ text: String, action: FeedbackAction? = nil) -> Self {
        snackbar(.success, text, action: action)
    }
    public static func error(_ text: String, action: FeedbackAction? = nil) -> Self {
        snackbar(.error, text, action: action)
    }
    public static func warning(_ text: String) -> Self { snackbar(.warning, text) }

    /// Instant feedback before a submit while offline, instead of waiting for a timeout.
    public static var offline: Self { snackbar(.warning, L10n.Error.network) }
}

extension FeedbackMessage: Equatable {
    /// Identical messages are de-duplicated by the queue; the action's closure isn't comparable, its title is.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.style == rhs.style && lhs.kind == rhs.kind && lhs.text == rhs.text
            && lhs.action?.title == rhs.action?.title && lhs.duration == rhs.duration
    }
}

/// View models show toasts and snackbars only through this (rule 26). DesignSystem's `FeedbackCenter`
/// implements it; tests use `MockFeedbackPresenter`.
@MainActor
public protocol FeedbackPresenting: AnyObject {
    func show(_ message: FeedbackMessage)
}

extension FeedbackPresenting {
    /// Error snackbar with the localized message and, when given, a Retry button.
    public func show(error: ResponseError, retry: (@MainActor @Sendable () -> Void)? = nil) {
        show(
            .error(error.localizedMessage, action: retry.map { FeedbackAction(title: L10n.Common.retry, handler: $0) }))
    }
}
