import Core
import SharedDomain
import __Feature__Domain

extension __Feature__ItemResponse {
    /// Validates invariants, then builds the entity (§3a). One test per guard.
    public func toEntity() throws(MappingError) -> __Feature__ItemEntity {
        guard !id.isEmpty else { throw .invalidValue("__feature_lower__.id", "empty") }
        guard !title.isEmpty else { throw .invalidValue("__feature_lower__.title", "empty") }
        return __Feature__ItemEntity(id: id, title: title)
    }
}

extension __Feature__PageResponse {
    public func toEntity() throws(MappingError) -> PaginatedEntity<__Feature__ItemEntity> {
        var entities: [__Feature__ItemEntity] = []
        for item in items {
            entities.append(try item.toEntity())
        }
        return PaginatedEntity(items: entities, page: page, hasNext: hasNext)
    }
}
