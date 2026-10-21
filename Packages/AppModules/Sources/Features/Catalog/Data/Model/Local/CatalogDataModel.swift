import Core
import CoreData

/// The catalog's Core Data model, merged into the app's single store by `AppContainer` (§6a).
public enum CatalogDataModel {
    public static func load() -> NSManagedObjectModel? {
        NSManagedObjectModel.named("Catalog", in: .module)
    }
}
