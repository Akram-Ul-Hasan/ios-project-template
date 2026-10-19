import SharedDomain
import os

/// Where an error happened, which changes how it's shown (§6o).
public enum ErrorContext: Sendable {
    /// First load of a screen: nothing else to show, so full-screen state.
    case initialLoad
    /// Pull to refresh: old data stays, so always a snackbar (§6m).
    case refresh
    /// Next page of a list: `PaginatedList` shows its own retry row.
    case pagination
    /// A user action (submit, add to cart): the screen stays, feedback is a snackbar, dialog or inline.
    case action
}

public enum ErrorTreatment: Equatable, Sendable {
    /// `EmptyStateView` with the message and Retry.
    case fullScreen
    /// Offline state that retries by itself when the connection returns.
    case offline
    case snackbar(retryable: Bool)
    /// Messages under the form fields, plus a snackbar for the general message.
    case inline
    case dialog
    /// Handled by the list's own retry row.
    case listRetry
    case forceLogout
    /// App-level blocking screen (maintenance, force update), shown by `RootView`.
    case blocking(SessionEvent)
    case silent
}

/// The only place the error table lives. Every view model goes through `ErrorHandling.handle`, never its own switch.
public enum ErrorPolicy {
    public static func treatment(for error: ResponseError, context: ErrorContext) -> ErrorTreatment {
        switch error {
        case .cancelled: return .silent
        case .unauthorized: return .forceLogout
        case .maintenance: return .blocking(.maintenance)
        case .updateRequired: return .blocking(.updateRequired)
        default: break
        }
        switch context {
        case .refresh: return .snackbar(retryable: isRetryable(error))
        case .pagination: return .listRetry
        case .initialLoad: return error == .network ? .offline : .fullScreen
        case .action:
            switch error {
            case .validation, .domain(.validation): return .inline
            case .business, .domain: return .dialog
            default: return .snackbar(retryable: isRetryable(error))
            }
        }
    }

    public static func isRetryable(_ error: ResponseError) -> Bool {
        switch error {
        case .network, .timeout, .server, .invalidResponse, .unknown: true
        default: false
        }
    }

    /// Logs at the table's level: endpoint-free, code-only, never PII.
    public static func log(_ error: ResponseError, context: ErrorContext) {
        let logger = AppLogger.ui
        let summary = describe(error)
        let place = String(describing: context)
        switch level(for: error) {
        case .debug: logger.debug("\(place, privacy: .public): \(summary, privacy: .public)")
        case .info: logger.info("\(place, privacy: .public): \(summary, privacy: .public)")
        case .default: logger.notice("\(place, privacy: .public): \(summary, privacy: .public)")
        default: logger.error("\(place, privacy: .public): \(summary, privacy: .public)")
        }
    }

    static func level(for error: ResponseError) -> OSLogType {
        switch error {
        case .cancelled: .debug
        case .validation, .business, .domain: .info
        case .network, .timeout, .unauthorized, .notFound, .maintenance, .updateRequired: .default
        case .forbidden, .server, .invalidResponse, .unknown: .error
        }
    }

    /// Case name and safe details only: server messages may contain user data, so they're left out.
    private static func describe(_ error: ResponseError) -> String {
        switch error {
        case .server(let status): "server(\(status))"
        case .business(let code, _): "business(\(code?.rawValue ?? "none"))"
        case .validation(_, let fields): "validation(\(fields.keys.sorted().joined(separator: ",")))"
        case .invalidResponse(let detail): "invalidResponse(\(detail))"
        case .domain(let domain): "domain(\(String(describing: domain)))"
        default: String(describing: error)
        }
    }
}
