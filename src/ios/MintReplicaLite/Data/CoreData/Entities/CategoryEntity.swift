// HUMAN TASKS:
// 1. Ensure Core Data model file (.xcdatamodeld) includes CategoryEntity with all properties defined
// 2. Run Core Data code generation for NSManagedObject subclasses if using automatic generation

// CoreData framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation
// Import relative to current file location
import "../../../Domain/Models/Category"

/// Core Data entity class representing a transaction category in the local database
/// Requirements addressed:
/// - Category Management (1.2 Scope/Financial Tracking)
/// - Local Data Storage (4.3.2 Client Storage/iOS)
@objc(CategoryEntity)
@objcMembers
public class CategoryEntity: NSManagedObject {
    // MARK: - Properties
    
    /// Unique identifier for the category
    @NSManaged public var id: UUID
    
    /// Name of the category
    @NSManaged public var name: String
    
    /// String representation of CategoryType
    @NSManaged public var type: String
    
    /// Optional parent category identifier
    @NSManaged public var parentId: UUID?
    
    /// Flag indicating if this is a system-defined category
    @NSManaged public var isSystem: Bool
    
    /// Timestamp when the category was created
    @NSManaged public var createdAt: Date
    
    /// Timestamp when the category was last updated
    @NSManaged public var updatedAt: Date
    
    // MARK: - Domain Conversion
    
    /// Converts Core Data entity to domain model
    /// - Returns: Category domain model instance
    public func toDomain() -> Category {
        // Create Category instance with required properties
        let category = try! Category(
            id: id,
            name: name,
            type: CategoryType(rawValue: type)!
        )
        
        // Use runtime modification to set read-only properties
        let mirror = Mirror(reflecting: category)
        mirror.children.forEach { child in
            switch child.label {
            case "parentId":
                setValue(parentId, forKey: "parentId")
            case "isSystem":
                setValue(isSystem, forKey: "isSystem")
            case "createdAt":
                setValue(createdAt, forKey: "createdAt")
            case "updatedAt":
                setValue(updatedAt, forKey: "updatedAt")
            default:
                break
            }
        }
        
        return category
    }
    
    /// Updates entity properties from domain model
    /// - Parameter category: Source Category domain model
    public func update(from category: Category) {
        id = category.id
        name = category.name
        type = category.type.rawValue
        parentId = category.parentId
        isSystem = category.isSystem
        createdAt = category.createdAt
        updatedAt = Date() // Always update timestamp on save
    }
}

// MARK: - Identifiable Conformance
extension CategoryEntity: Identifiable {
    
    /// Creates or updates CategoryEntity from domain model
    /// - Parameters:
    ///   - category: Source Category domain model
    ///   - context: NSManagedObjectContext for persistence
    /// - Returns: CategoryEntity instance
    public static func fromDomain(
        _ category: Category,
        context: NSManagedObjectContext
    ) -> CategoryEntity {
        // Create fetch request to find existing entity
        let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        // Try to fetch existing entity or create new one
        let entity: CategoryEntity
        if let existingEntity = try? context.fetch(fetchRequest).first {
            entity = existingEntity
        } else {
            entity = CategoryEntity(context: context)
        }
        
        // Update entity properties
        entity.update(from: category)
        
        return entity
    }
}