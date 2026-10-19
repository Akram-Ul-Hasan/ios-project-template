import Foundation
import SharedDomain

/// THE app error (§6o). Every failure from any layer becomes one of these through `ResponseError.from(_:)`;
/// `ErrorPolicy` then decides how the UI treats it.
public enum ResponseError: Error, Equatable, Sendable {
    case network
    case timeout
    case unauthorized
    case forbidden
    case notFound
    /// 422. `fieldErrors` keys are API field names, applied to forms through `FormState.applyServerErrors`.
    case validation(message: String?, fieldErrors: [String: [String]])
    /// 409 / domain codes such as OUT_OF_STOCK. `code` is `nil` when the backend sent none.
    case business(code: BackendErrorCode?, message: String?)
    case server(statusCode: Int)
    case maintenance
    case updateRequired
    /// The response broke the API contract (§3a). `detail` has the key path and reason, never values.
    case invalidResponse(detail: String)
    case domain(DomainError)
    case cancelled
    case unknown
}

extension ResponseError {
    public static func from(_ error: any Error) -> ResponseError {
        switch error {
        case let error as ResponseError: error
        case let error as DomainError: .domain(error)
        case is CancellationError: .cancelled
        case let error as URLError: from(error)
        case let error as DecodingError: .invalidResponse(detail: describe(error))
        default: .unknown
        }
    }

    /// Maps a non-2xx status and its (optional) error body.
    public static func from(statusCode: Int, body: BackendError?) -> ResponseError {
        // No field errors in the body means the same as an empty map.
        let fieldErrors = body?.errors ?? [:]
        switch statusCode {
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 409: return .business(code: body?.code, message: body?.message)
        case 422: return .validation(message: body?.message, fieldErrors: fieldErrors)
        case 426: return .updateRequired
        case 503: return .maintenance
        case 500...599: return .server(statusCode: statusCode)
        case 400...499:
            if !fieldErrors.isEmpty { return .validation(message: body?.message, fieldErrors: fieldErrors) }
            if let code = body?.code { return .business(code: code, message: body?.message) }
            return .unknown
        default: return .unknown
        }
    }

    private static func from(_ error: URLError) -> ResponseError {
        switch error.code {
        case .cancelled:
            .cancelled
        case .timedOut:
            .timeout
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff,
            .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .callIsActive:
            .network
        default:
            .unknown
        }
    }

    private static func describe(_ error: DecodingError) -> String {
        func path(_ codingPath: [any CodingKey]) -> String {
            let joined = codingPath.map { $0.intValue.map { "[\($0)]" } ?? $0.stringValue }.joined(separator: ".")
            return joined.isEmpty ? "<root>" : joined
        }
        switch error {
        case .keyNotFound(let key, let context): return "missing key \(path(context.codingPath + [key]))"
        case .valueNotFound(let type, let context): return "null \(type) at \(path(context.codingPath))"
        case .typeMismatch(let type, let context): return "expected \(type) at \(path(context.codingPath))"
        case .dataCorrupted(let context): return "corrupted data at \(path(context.codingPath))"
        @unknown default: return "decoding failed"
        }
    }
}
