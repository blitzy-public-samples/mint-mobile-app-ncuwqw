//
// InvestmentRepository.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify Core Data model schema matches InvestmentEntity definition
// 2. Configure proper Core Data migration strategy for schema updates
// 3. Review error handling and logging requirements with team
// 4. Set up performance monitoring for database operations

// CoreData framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation

// Relative imports
import "../Domain/Models/Investment"
import "../CoreData/Entities/InvestmentEntity"
import "../CoreData/CoreDataManager"

/// Thread-safe repository class for managing investment data persistence using Core Data
/// Implements:
/// - Investment Tracking (Section 1.2): Portfolio monitoring and investment account integration
/// - Local Data Persistence (Section 4.3.2): Core Data for investment data storage
final class InvestmentRepository {
    
    // MARK: - Properties
    
    private let coreDataManager: CoreDataManager
    
    // MARK: - Initialization
    
    /// Initializes repository with CoreDataManager instance
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - Public Methods
    
    /// Retrieves an investment by ID from Core Data
    /// - Parameter id: UUID of the investment to retrieve
    /// - Returns: Optional Investment domain model if found
    func getInvestment(id: UUID) -> Investment? {
        var investment: Investment?
        
        coreDataManager.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<InvestmentEntity> = InvestmentEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                if let entity = try context.fetch(fetchRequest).first {
                    investment = entity.toDomainModel()
                }
            } catch {
                print("Error fetching investment: \(error.localizedDescription)")
            }
        }
        
        return investment
    }
    
    /// Retrieves all investments for an account
    /// - Parameter accountId: UUID of the account
    /// - Returns: Array of Investment domain models
    func getInvestments(accountId: UUID) -> [Investment] {
        var investments: [Investment] = []
        
        coreDataManager.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<InvestmentEntity> = InvestmentEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "accountId == %@", accountId as CVarArg)
            
            do {
                let entities = try context.fetch(fetchRequest)
                investments = entities.map { $0.toDomainModel() }
            } catch {
                print("Error fetching investments: \(error.localizedDescription)")
            }
        }
        
        return investments
    }
    
    /// Saves or updates an investment in Core Data
    /// - Parameter investment: Investment domain model to save
    /// - Returns: Result containing updated Investment model or error
    func saveInvestment(investment: Investment) -> Result<Investment, Error> {
        var result: Result<Investment, Error>!
        
        coreDataManager.performBackgroundTask { context in
            do {
                // Check if investment already exists
                let fetchRequest: NSFetchRequest<InvestmentEntity> = InvestmentEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", investment.id as CVarArg)
                
                let entity: InvestmentEntity
                if let existingEntity = try context.fetch(fetchRequest).first {
                    entity = existingEntity
                } else {
                    entity = InvestmentEntity(context: context)
                }
                
                // Update entity with domain model data
                entity.update(with: investment)
                
                // Save context changes
                try context.save()
                
                result = .success(entity.toDomainModel())
            } catch {
                result = .failure(error)
            }
        }
        
        return result
    }
    
    /// Deletes an investment from Core Data
    /// - Parameter id: UUID of the investment to delete
    /// - Returns: Result indicating success or failure
    func deleteInvestment(id: UUID) -> Result<Void, Error> {
        var result: Result<Void, Error>!
        
        coreDataManager.performBackgroundTask { context in
            do {
                let fetchRequest: NSFetchRequest<InvestmentEntity> = InvestmentEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                
                if let entity = try context.fetch(fetchRequest).first {
                    context.delete(entity)
                    try context.save()
                    result = .success(())
                } else {
                    result = .failure(NSError(domain: "InvestmentRepository",
                                            code: 404,
                                            userInfo: [NSLocalizedDescriptionKey: "Investment not found"]))
                }
            } catch {
                result = .failure(error)
            }
        }
        
        return result
    }
    
    /// Updates investment price and recalculates values
    /// - Parameters:
    ///   - id: UUID of the investment to update
    ///   - newPrice: New price value
    /// - Returns: Result containing updated Investment model or error
    func updateInvestmentPrice(id: UUID, newPrice: Decimal) -> Result<Investment, Error> {
        var result: Result<Investment, Error>!
        
        coreDataManager.performBackgroundTask { context in
            do {
                let fetchRequest: NSFetchRequest<InvestmentEntity> = InvestmentEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                
                if let entity = try context.fetch(fetchRequest).first {
                    // Get domain model and update price
                    var investment = entity.toDomainModel()
                    investment.updatePrice(newPrice)
                    
                    // Update entity with new values
                    entity.update(with: investment)
                    
                    try context.save()
                    result = .success(entity.toDomainModel())
                } else {
                    result = .failure(NSError(domain: "InvestmentRepository",
                                            code: 404,
                                            userInfo: [NSLocalizedDescriptionKey: "Investment not found"]))
                }
            } catch {
                result = .failure(error)
            }
        }
        
        return result
    }
}