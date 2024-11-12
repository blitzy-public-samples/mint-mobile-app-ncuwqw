// HUMAN TASKS:
// 1. Ensure Core Data model file (.xcdatamodeld) includes BudgetEntity with all properties defined
// 2. Run Core Data code generation for NSManagedObject subclasses if using automatic generation
// 3. Verify that the database schema migration strategy is in place for any model changes

// CoreData framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation

// Import relative to current file location
import "../../../Domain/Models/Budget"

/// CoreData managed object subclass representing a budget in the local database
/// Requirements addressed:
/// - Category-based budgeting (1.2 Scope/Budget Management)
/// - Local Data Persistence (4.3.2 Client Storage/iOS)
/// - Progress monitoring (1.2 Scope/Budget Management)
@objc(BudgetEntity)
@objcMembers
final class BudgetEntity: NSManagedObject {
    
    // MARK: - Properties
    
    /// Unique identifier for the budget
    @NSManaged public var id: UUID
    
    /// Allocated budget amount
    @NSManaged public var amount: NSDecimalNumber
    
    /// Current spent amount
    @NSManaged public var spent: NSDecimalNumber
    
    /// Budget period type as string
    @NSManaged public var period: String
    
    /// Alert threshold percentage (0.0 to 1.0)
    @NSManaged public var alertThreshold: Double
    
    /// Flag indicating if alerts are enabled
    @NSManaged public var alertEnabled: Bool
    
    /// Budget period start date
    @NSManaged public var startDate: Date
    
    /// Budget period end date
    @NSManaged public var endDate: Date
    
    /// Timestamp when the budget was created
    @NSManaged public var createdAt: Date
    
    /// Timestamp when the budget was last updated
    @NSManaged public var updatedAt: Date
    
    /// Associated category entity
    @NSManaged public var category: CategoryEntity
    
    /// Related transactions set
    @NSManaged public var transactions: NSSet?
    
    // MARK: - Initialization
    
    /// Initializes a new budget entity in the specified context
    /// - Parameter context: NSManagedObjectContext for persistence
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        
        // Set default values
        self.amount = NSDecimalNumber.zero
        self.spent = NSDecimalNumber.zero
        self.alertThreshold = 0.75 // Default 75% threshold
        self.alertEnabled = true
        
        // Set timestamps
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
    
    // MARK: - Domain Conversion
    
    /// Converts CoreData entity to domain model
    /// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
    /// - Returns: Budget domain model instance
    func toDomain() -> Budget {
        // Convert period string to BudgetPeriod enum
        let budgetPeriod = BudgetPeriod(rawValue: period)!
        
        // Create Budget instance with required properties
        let budget = try! Budget(
            id: id,
            categoryId: category.id,
            amount: amount.decimalValue,
            period: budgetPeriod,
            alertThreshold: alertThreshold,
            alertEnabled: alertEnabled,
            startDate: startDate,
            endDate: endDate
        )
        
        // Use runtime modification to set read-only properties
        let mirror = Mirror(reflecting: budget)
        mirror.children.forEach { child in
            switch child.label {
            case "spent":
                setValue(spent.decimalValue, forKey: "spent")
            case "createdAt":
                setValue(createdAt, forKey: "createdAt")
            case "updatedAt":
                setValue(updatedAt, forKey: "updatedAt")
            default:
                break
            }
        }
        
        return budget
    }
    
    /// Updates entity properties from domain model
    /// - Parameter budget: Source Budget domain model
    func update(from budget: Budget) {
        id = budget.id
        amount = NSDecimalNumber(decimal: budget.amount)
        spent = NSDecimalNumber(decimal: budget.spent)
        period = budget.period.rawValue
        alertThreshold = budget.alertThreshold
        alertEnabled = budget.alertEnabled
        startDate = budget.startDate
        endDate = budget.endDate
        createdAt = budget.createdAt
        updatedAt = Date() // Always update timestamp on save
    }
    
    // MARK: - Budget Calculations
    
    /// Calculates remaining budget amount
    /// Requirement: Progress monitoring (1.2 Scope/Budget Management)
    /// - Returns: Remaining budget amount as NSDecimalNumber
    func getRemainingAmount() -> NSDecimalNumber {
        return amount.subtracting(spent)
    }
    
    /// Calculates budget utilization percentage
    /// Requirement: Progress monitoring (1.2 Scope/Budget Management)
    /// - Returns: Budget utilization percentage as Double
    func getProgress() -> Double {
        guard amount.compare(NSDecimalNumber.zero) == .orderedDescending else {
            return 0.0
        }
        return Double(truncating: spent.dividing(by: amount))
    }
}