import SharedDomain

/// Signs in. Re-runs the same rules as the form (defense in depth, §6o), so a business rule never lives only in the UI.
public struct LoginUseCase: UseCase {
    private let repository: any AuthRepository

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ input: LoginInputEntity) async throws -> UserEntity {
        if let error = ValidationRule.all([Rules.required, Rules.phoneBD]).validate(input.phone) {
            throw DomainError.validation(field: Field.phone, error: error)
        }
        if let error = Rules.required.validate(input.password) {
            throw DomainError.validation(field: Field.password, error: error)
        }
        return try await repository.login(input)
    }

    /// API field names, shared with the form so errors land under the right input.
    public enum Field {
        public static let phone = "phone"
        public static let password = "password"
    }
}
