import CoreData
import Foundation

/// Cached product row (Codegen: Manual/None). `@NSManaged` properties are optional by nature, so
/// `toEntity()` validates every row (§3a). Never leaves a `context.perform { }` block.
@objc(ProductDBModel)
final class ProductDBModel: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var name: String?
    @NSManaged var price: NSDecimalNumber?
    @NSManaged var discountPrice: NSDecimalNumber?
    @NSManaged var imageURL: String?
    @NSManaged var tags: String?
    @NSManaged var status: String?
    @NSManaged var position: Int64
    @NSManaged var cachedAt: Date?

    @nonobjc static func fetchRequest() -> NSFetchRequest<ProductDBModel> {
        NSFetchRequest<ProductDBModel>(entityName: "ProductDBModel")
    }
}
