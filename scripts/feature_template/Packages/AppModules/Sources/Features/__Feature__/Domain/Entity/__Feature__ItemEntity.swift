/// Data only (rule 1): every property passed in `init`, no defaults.
public struct __Feature__ItemEntity: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
