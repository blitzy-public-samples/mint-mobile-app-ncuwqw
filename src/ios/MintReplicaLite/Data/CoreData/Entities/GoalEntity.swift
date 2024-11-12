//
// GoalEntity.swift
// MintReplicaLite
//

// HUMAN TASKS:
// 1. Verify Core Data model schema matches this implementation
// 2. Ensure Core Data model version and migration strategy is in place
// 3. Validate indexes are properly set up in Core Data model for optimal query performance
// 4. Review error handling strategy for Core Data operations

// CoreData framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation

// Import domain model relatively
import "../../../Domain/Models/Goal"

// Implements requirements:
// - Goal Management (1.2 Scope/Goal Management)
// - Local Data Persistence (4.3.2 Client Storage/iOS)
@objc(GoalEntity)
public class GoalEntity: NSManagedObject {
    
    // MARK: - Properties
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var goalDescription: String
    @NSManaged public var type: Int16
    @NSManaged public var targetAmount: NSDecimalNumber
    @NSManaged public var currentAmount: NSDecimalNumber
    @NSManaged public var targetDate: Date
    @NSManaged public var startDate: Date
    @NSManaged public var linkedAccountIds: Set<String>
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // MARK: - Lifecycle
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
        updatedAt = Date()
    }
    
    // MARK: - Domain Model Conversion
    
    /// Converts the Core Data entity to a domain model instance
    public func toDomainModel() -> Goal {
        // Create Goal instance with required properties
        let goal = try! Goal(
            name: name,
            type: GoalType(rawValue: Int(type))!,
            targetAmount: targetAmount.decimalValue,
            targetDate: targetDate
        )
        
        // Map remaining properties
        goal.goalDescription = goalDescription
        try! goal.updateProgress(amount: currentAmount.decimalValue)
        goal.startDate = startDate
        
        // Convert string IDs back to UUIDs
        goal.linkedAccountIds = Set(linkedAccountIds.compactMap { UUID(uuidString: $0) })
        goal.isActive = isActive
        
        return goal
    }
    
    /// Updates the entity with data from a domain model
    public func update(with goal: Goal) {
        id = goal.id
        name = goal.name
        goalDescription = goal.goalDescription
        type = Int16(goal.type.rawValue)
        targetAmount = NSDecimalNumber(decimal: goal.targetAmount)
        currentAmount = NSDecimalNumber(decimal: goal.currentAmount)
        targetDate = goal.targetDate
        startDate = goal.startDate
        linkedAccountIds = Set(goal.linkedAccountIds.map { $0.uuidString })
        isActive = goal.isActive
        updatedAt = Date()
    }
}

// MARK: - Fetch Request Extension

extension GoalEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalEntity> {
        return NSFetchRequest<GoalEntity>(entityName: "GoalEntity")
    }
}