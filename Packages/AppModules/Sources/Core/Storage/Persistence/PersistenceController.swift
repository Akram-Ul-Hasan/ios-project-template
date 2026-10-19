import CoreData
import Foundation

/// One Core Data store for the whole app, merged from each feature's `.xcdatamodeld` (§6a).
/// Created once in `AppContainer`; `NSManagedObject`s never leave a data source's `context.perform { }`.
public final class PersistenceController: @unchecked Sendable {
    // @unchecked: NSPersistentContainer is used only through thread-safe entry points
    // (newBackgroundContext, viewContext on main, loading guarded by `load()`).
    public let container: NSPersistentContainer

    public enum Location: Sendable {
        /// Application Support (default).
        case onDisk
        /// SQLite at /dev/null: nothing persisted, batch requests still work. Tests and previews.
        case inMemory
        case at(URL)
    }

    public init(name: String, models: [NSManagedObjectModel], location: Location) {
        let model = NSManagedObjectModel(byMerging: models) ?? NSManagedObjectModel()
        container = NSPersistentContainer(name: name, managedObjectModel: model)
        let description = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        switch location {
        case .onDisk: break
        case .inMemory: description.url = URL(filePath: "/dev/null")
        case .at(let url): description.url = url
        }
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        #if os(iOS)
            description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        #endif
        container.persistentStoreDescriptions = [description]
    }

    /// Opens the store off the main thread.
    @concurrent
    public func load() async throws {
        try loadStores()
        container.viewContext.automaticallyMergesChangesFromParent = true
        excludeFromBackup()
    }

    private func loadStores() throws {
        var loadError: (any Error)?
        // Synchronous because shouldAddStoreAsynchronously = false.
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
    }

    private func excludeFromBackup() {
        for url in container.persistentStoreDescriptions.compactMap(\.url) where url.path() != "/dev/null" {
            for suffix in ["", "-wal", "-shm"] {
                var file = URL(filePath: url.path() + suffix)
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try? file.setResourceValues(values)
            }
        }
    }
}

extension PersistenceController: SessionCleanable {
    /// Deletes every row of every entity (logout).
    public func clearSessionData() async throws {
        let context = container.newBackgroundContext()
        let entityNames = container.managedObjectModel.entities.compactMap(\.name)
        let deleted = try await context.perform {
            var ids: [NSManagedObjectID] = []
            for name in entityNames {
                let request = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: name))
                request.resultType = .resultTypeObjectIDs
                let result = try context.execute(request) as? NSBatchDeleteResult
                ids += result?.result as? [NSManagedObjectID] ?? []
            }
            return ids
        }
        let viewContext = container.viewContext
        await viewContext.perform {
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSDeletedObjectsKey: deleted], into: [viewContext])
        }
    }
}

extension NSManagedObjectModel {
    /// A feature's compiled model: `NSManagedObjectModel.named("Auth", in: .module)`.
    public static func named(_ name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        guard
            let url = bundle.url(forResource: name, withExtension: "momd")
                ?? bundle.url(forResource: name, withExtension: "mom")
        else { return nil }
        return NSManagedObjectModel(contentsOf: url)
    }
}
