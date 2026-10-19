/// Error body the backend sends with non-2xx responses: `{ "code": "OUT_OF_STOCK", "message": "…", "errors": { "phone": ["…"] } }`.
/// All optional: error bodies are best effort, and a missing body still maps by status code.
public struct BackendError: Decodable, Equatable, Sendable {
    public let code: BackendErrorCode?
    public let message: String?
    public let errors: [String: [String]]?

    public init(code: BackendErrorCode?, message: String?, errors: [String: [String]]?) {
        self.code = code
        self.message = message
        self.errors = errors
    }
}
