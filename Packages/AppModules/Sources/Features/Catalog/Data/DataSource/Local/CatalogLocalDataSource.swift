import Core
import CoreData
import Foundation
import SharedDomain

/// The cached first page of the catalog, so the home screen has something to show offline.
/// All Core Data work happens on background contexts; only entities leave this type (§6a).
public struct CatalogLocalDataSource: Sendable {
    private let persistence: PersistenceController

    public init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    /// Replaces the cache with `products`, keeping their order.
    public func replaceFirstPage(with products: [ProductEntity]) async throws {
        let context = persistence.container.newBackgroundContext()
        try await context.perform {
            try Self.deleteAll(in: context)
            let now = Date.now
            for (position, product) in products.enumerated() {
                ProductDBModel(context: context).update(from: product, position: position, cachedAt: now)
            }
            try context.save()
        }
    }

    /// `nil` when there's no cache. A corrupted row wipes the cache and counts as a miss (§3a).
    public func cachedFirstPage() async throws -> [ProductEntity]? {
        let context = persistence.container.newBackgroundContext()
        return try await context.perform { () throws -> [ProductEntity]? in
            let request = ProductDBModel.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
            let rows = try context.fetch(request)
            guard !rows.isEmpty else { return nil }
            do {
                return try rows.map { try $0.toEntity() }
            } catch {
                let detail = (error as? MappingError)?.detail ?? "unreadable row"
                AppLogger.persistence.error("corrupted catalog cache, discarding: \(detail, privacy: .public)")
                try Self.deleteAll(in: context)
                try context.save()
                return nil
            }
        }
    }

    private static func deleteAll(in context: NSManagedObjectContext) throws {
        for row in try context.fetch(ProductDBModel.fetchRequest()) {
            context.delete(row)
        }
    }
}
