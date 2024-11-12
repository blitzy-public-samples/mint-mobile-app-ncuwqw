//
// InvestmentEntity.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify Core Data model schema matches this entity definition
// 2. Ensure Core Data migrations are set up for schema changes
// 3. Review decimal number precision requirements for financial calculations
// 4. Confirm index configuration for frequently queried properties

// CoreData framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation

// Import domain model relatively
import "../../../Domain/Models/Investment"

/// Core Data entity class for persisting investment data
/// Implements:
/// - Investment Tracking (Section 1.2): Portfolio data persistence
/// - Local Data Persistence (Section 4.3.2): Core Data integration
@objc(InvestmentEntity)
public class InvestmentEntity: NSManagedObject {
    
    // MARK: - Properties
    @NSManaged public var id: UUID
    @NSManaged public var accountId: UUID
    @NSManaged public var symbol: String
    @NSManaged public var name: String
    @NSManaged public var type: String
    @NSManaged public var shares: NSDecimalNumber
    @NSManaged public var costBasis: NSDecimalNumber
    @NSManaged public var currentPrice: NSDecimalNumber
    @NSManaged public var currentValue: NSDecimalNumber
    @NSManaged public var returnAmount: NSDecimalNumber
    @NSManaged public var returnPercentage: NSDecimalNumber
    @NSManaged public var lastUpdated: Date
    @NSManaged public var purchaseDate: Date
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // MARK: - Lifecycle
    
    /// Configure default values when creating new instances
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        let now = Date()
        createdAt = now
        updatedAt = now
        lastUpdated = now
        purchaseDate = now
        
        // Initialize decimal numbers with zero
        shares = NSDecimalNumber.zero
        costBasis = NSDecimalNumber.zero
        currentPrice = NSDecimalNumber.zero
        currentValue = NSDecimalNumber.zero
        returnAmount = NSDecimalNumber.zero
        returnPercentage = NSDecimalNumber.zero
    }
    
    // MARK: - Domain Model Conversion
    
    /// Converts Core Data entity to domain model
    /// Implements Investment Tracking requirement for data mapping
    public func toDomainModel() -> Investment {
        // Convert string type to enum
        let investmentType = InvestmentType(rawValue: type) ?? .other
        
        // Create investment instance with converted properties
        let investment = Investment(
            id: id,
            accountId: accountId,
            symbol: symbol,
            name: name,
            type: investmentType,
            shares: shares.decimalValue,
            costBasis: costBasis.decimalValue,
            currentPrice: currentPrice.decimalValue
        )
        
        return investment
    }
    
    /// Updates entity with domain model data
    /// Implements Local Data Persistence requirement for data synchronization
    public func update(with model: Investment) {
        id = model.id
        accountId = model.accountId
        symbol = model.symbol
        name = model.name
        type = model.type.rawValue
        
        // Convert Decimal to NSDecimalNumber for Core Data storage
        shares = NSDecimalNumber(decimal: model.shares)
        costBasis = NSDecimalNumber(decimal: model.costBasis)
        currentPrice = NSDecimalNumber(decimal: model.currentPrice)
        currentValue = NSDecimalNumber(decimal: model.currentValue)
        returnAmount = NSDecimalNumber(decimal: model.returnAmount)
        returnPercentage = NSDecimalNumber(decimal: model.returnPercentage)
        
        // Update timestamps
        lastUpdated = model.lastUpdated
        purchaseDate = model.purchaseDate
        updatedAt = Date()
        
        // Ensure Core Data knows about our changes
        setPrimitiveValue(updatedAt, forKey: "updatedAt")
    }
}

// MARK: - Identifiable Conformance
extension InvestmentEntity: Identifiable {
    // Use UUID as identifier for SwiftUI integration
}