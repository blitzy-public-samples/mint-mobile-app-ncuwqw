//
// AccountEntity.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Configure Core Data model file (.xcdatamodeld) with matching entity attributes and types
// 2. Set up encryption keys and certificates for field-level encryption
// 3. Verify data migration strategy for schema updates
// 4. Review data retention policies for account information

// CoreData framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation

// Relative import for domain model
import "../../../Domain/Models/Account"

/// Core Data entity class representing a financial account in the local database
/// Implements:
/// - Account Management (Section 1.2): Financial account persistence
/// - Data Security (Section 2.4): Secure field-level encryption
/// - Local Data Persistence (Section 4.3.2): Core Data integration
@objc(AccountEntity)
public class AccountEntity: NSManagedObject {
    
    // MARK: - Properties
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var institutionId: String
    @NSManaged public var accountNumber: String
    @NSManaged public var type: String
    @NSManaged public var balance: NSDecimalNumber
    @NSManaged public var isActive: Bool
    @NSManaged public var lastSyncDate: Date
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // MARK: - Lifecycle
    
    /// Configure default values when creating new instances
    /// Implements Local Data Persistence requirement for data initialization
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        let now = Date()
        createdAt = now
        updatedAt = now
        isActive = true
    }
    
    // MARK: - Domain Mapping
    
    /// Converts Core Data entity to domain model
    /// Implements Account Management requirement for data access
    func toDomain() -> Account {
        return Account(
            id: id,
            name: name,
            institutionId: institutionId,
            accountNumber: accountNumber,
            type: AccountType(rawValue: type) ?? .other,
            balance: balance as Decimal
        )
    }
    
    /// Updates entity properties from domain model
    /// Implements Account Management requirement for data updates
    func update(from account: Account) {
        self.id = account.id
        self.name = account.name
        self.institutionId = account.institutionId
        self.accountNumber = account.accountNumber
        self.type = account.type.rawValue
        self.balance = NSDecimalNumber(decimal: account.balance)
        self.isActive = account.isActive
        self.lastSyncDate = account.lastSyncDate
        self.updatedAt = Date()
        // Preserve original creation timestamp
    }
}

// MARK: - Fetch Request Extension
extension AccountEntity {
    
    /// Provides a typed fetch request for AccountEntity
    /// Implements Local Data Persistence requirement for data querying
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccountEntity> {
        return NSFetchRequest<AccountEntity>(entityName: "AccountEntity")
    }
}