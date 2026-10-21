/// Mirrors the API contract (§3a): required = non-optional, nullable = optional.
public struct __Feature__ItemResponse: Decodable, Equatable, Sendable {
    public let id: String
    public let title: String
}

public struct __Feature__PageResponse: Decodable, Sendable {
    public let items: [__Feature__ItemResponse]
    public let page: Int
    public let hasNext: Bool
}
