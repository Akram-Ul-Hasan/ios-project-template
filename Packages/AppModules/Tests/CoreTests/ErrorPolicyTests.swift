import SharedDomain
import Testing

@testable import Core

@Suite("ErrorPolicy")
struct ErrorPolicyTests {
    @Test(
        "App-level errors win in every context",
        arguments: [ErrorContext.initialLoad, .refresh, .pagination, .action])
    func appLevel(context: ErrorContext) {
        #expect(ErrorPolicy.treatment(for: .cancelled, context: context) == .silent)
        #expect(ErrorPolicy.treatment(for: .unauthorized, context: context) == .forceLogout)
        #expect(ErrorPolicy.treatment(for: .maintenance, context: context) == .blocking(.maintenance))
        #expect(ErrorPolicy.treatment(for: .updateRequired, context: context) == .blocking(.updateRequired))
    }

    @Test(
        "Initial load: offline state for network, full screen otherwise",
        arguments: [
            (ResponseError.network, ErrorTreatment.offline), (.timeout, .fullScreen), (.notFound, .fullScreen),
            (.server(statusCode: 500), .fullScreen),
        ])
    func initialLoad(error: ResponseError, expected: ErrorTreatment) {
        #expect(ErrorPolicy.treatment(for: error, context: .initialLoad) == expected)
    }

    @Test("Refresh is always a snackbar; pagination uses the list's retry row")
    func refreshAndPagination() {
        #expect(ErrorPolicy.treatment(for: .network, context: .refresh) == .snackbar(retryable: true))
        #expect(ErrorPolicy.treatment(for: .forbidden, context: .refresh) == .snackbar(retryable: false))
        #expect(ErrorPolicy.treatment(for: .server(statusCode: 502), context: .pagination) == .listRetry)
    }

    @Test(
        "Actions: inline for validation, dialog for business rules, snackbar otherwise",
        arguments: [
            (ResponseError.validation(message: nil, fieldErrors: [:]), ErrorTreatment.inline),
            (.domain(.validation(field: "phone", error: .required)), .inline),
            (.business(code: .outOfStock, message: nil), .dialog),
            (.domain(.subscriptionRequired), .dialog),
            (.network, .snackbar(retryable: true)),
            (.notFound, .snackbar(retryable: false)),
        ])
    func actions(error: ResponseError, expected: ErrorTreatment) {
        #expect(ErrorPolicy.treatment(for: error, context: .action) == expected)
    }

    @Test("Log levels follow the table")
    func levels() {
        #expect(ErrorPolicy.level(for: .cancelled) == .debug)
        #expect(ErrorPolicy.level(for: .validation(message: nil, fieldErrors: [:])) == .info)
        #expect(ErrorPolicy.level(for: .network) == .default)
        #expect(ErrorPolicy.level(for: .server(statusCode: 500)) == .error)
    }
}
