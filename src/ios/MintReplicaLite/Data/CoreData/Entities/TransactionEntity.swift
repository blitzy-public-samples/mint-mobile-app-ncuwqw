// HUMAN TASKS:
// 1. Configure Core Data model file (.xcdatamodeld) with matching entity attributes and types
// 2. Set up encryption keys and certificates for field-level encryption of sensitive transaction data
// 3. Verify data migration strategy for schema updates
// 4. Review transaction amount rounding rules with financial compliance team

// CoreData framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation

// Relative imports for domain models
import "../../../Domain/Models/Transaction"
import "AccountEntity"
import "CategoryEntity"

/// Core Data managed object subclass representing a financial transaction with secure field-level encryption
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking): Transaction persistence and management
/// - Transaction Data Security (6.2.2 Sensitive Data Handling): Secure field-level encryption
/// - Local Data Storage (4.3.2 Client Storage/iOS): Core Data implementation
@objc(TransactionEntity)
@objcMembers
public class TransactionEntity: NSManagedObject {
    
    // MARK: - Properties
    
    /// Unique identifier for the transaction
    @NSManaged public var id: UUID
    
    /// Associated account identifier
    @NSManaged public var accountId: UUID
    
    /// Optional category identifier
    @NSManaged public var categoryId: UUID?
    
    /// Transaction amount stored as NSDecimalNumber for precision
    @NSManaged public var amount: NSDecimalNumber
    
    /// Transaction date
    @NSManaged public var date: Date
    
    /// Encrypted transaction description
    @NSManaged public var transactionDescription: String
    
    /// Optional encrypted notes
    @NSManaged public var notes: String?
    
    /// String representation of TransactionType enum
    @NSManaged public var type: String
    
    /// String representation of TransactionStatus enum
    @NSManaged public var status: String
    
    /// Flag indicating if transaction is recurring
    @NSManaged public var isRecurring: Bool
    
    /// Optional encrypted merchant name
    @NSManaged public var merchantName: String?
    
    /// Creation timestamp
    @NSManaged public var createdAt: Date
    
    /// Last update timestamp
    @NSManaged public var updatedAt: Date
    
    // MARK: - Lifecycle
    
    /// Configure default values when creating new instances
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        let now = Date()
        createdAt = now
        updatedAt = now
    }
    
    // MARK: - Domain Conversion
    
    /// Converts Core Data entity to domain model
    /// Implements Financial Tracking requirement for data access
    func toDomain() -> Transaction {
        // Create Transaction instance with required properties
        let transaction = Transaction(
            id: id,
            accountId: accountId,
            amount: amount as Decimal,
            description: transactionDescription,
            type: TransactionType(rawValue: type) ?? .debit
        )
        
        // Use runtime modification to set read-only properties
        let mirror = Mirror(reflecting: transaction)
        mirror.children.forEach { child in
            switch child.label {
            case "categoryId":
                setValue(categoryId, forKey: "categoryId")
            case "notes":
                setValue(notes, forKey: "notes")
            case "status":
                setValue(TransactionStatus(rawValue: status) ?? .pending, forKey: "status")
            case "isRecurring":
                setValue(isRecurring, forKey: "isRecurring")
            case "merchantName":
                setValue(merchantName, forKey: "merchantName")
            case "date":
                setValue(date, forKey: "date")
            case "createdAt":
                setValue(createdAt, forKey: "createdAt")
            case "updatedAt":
                setValue(updatedAt, forKey: "updatedAt")
            default:
                break
            }
        }
        
        return transaction
    }
    
    /// Updates entity properties from domain model
    /// Implements Financial Tracking requirement for data updates
    func update(from transaction: Transaction) {
        self.id = transaction.id
        self.accountId = transaction.accountId
        self.categoryId = transaction.categoryId
        self.amount = NSDecimalNumber(decimal: transaction.amount)
        self.date = transaction.date
        self.transactionDescription = transaction.description
        self.notes = transaction.notes
        self.type = transaction.type.rawValue
        self.status = transaction.status.rawValue
        self.isRecurring = transaction.isRecurring
        self.merchantName = transaction.merchantName
        // Preserve original creation timestamp
        self.updatedAt = Date()
    }
}

// MARK: - Identifiable Conformance
extension TransactionEntity: Identifiable {
    
    /// Creates or updates TransactionEntity from domain model
    /// Implements Financial Tracking requirement for data persistence
    public static func fromDomain(
        _ transaction: Transaction,
        context: NSManagedObjectContext
    ) -> TransactionEntity {
        // Create fetch request to find existing entity
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", transaction.id as CVarArg)
        
        // Try to fetch existing entity or create new one
        let entity: TransactionEntity
        if let existingEntity = try? context.fetch(fetchRequest).first {
            entity = existingEntity
        } else {
            entity = TransactionEntity(context: context)
        }
        
        // Update entity properties
        entity.update(from: transaction)
        
        return entity
    }
    
    /// Provides a typed fetch request for TransactionEntity
    /// Implements Local Data Storage requirement for data querying
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionEntity> {
        return NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
    }
}