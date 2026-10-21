public struct LoginInputEntity: Equatable, Sendable {
    public let phone: String
    public let password: String

    public init(phone: String, password: String) {
        self.phone = phone
        self.password = password
    }
}
