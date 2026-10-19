/// One business operation (rule 3). Implementations are small structs called like functions:
/// `let user = try await login(input)`.
public protocol UseCase: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    func callAsFunction(_ input: Input) async throws -> Output
}

extension UseCase where Input == Void {
    /// Lets input-less use cases be called as `try await logout()`.
    public func callAsFunction() async throws -> Output {
        try await callAsFunction(())
    }
}
