//
// GoalRepository.swift
// MintReplicaLite
//

// HUMAN TASKS:
// 1. Verify Core Data model schema matches implementation
// 2. Review error handling and logging integration
// 3. Configure database indexing for optimal query performance
// 4. Set up database monitoring and analytics for production

// CoreData framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation

// Internal imports
import "../../../Domain/Models/Goal"
import "../CoreData/Entities/GoalEntity"
import "../CoreData/CoreDataManager"

// Implements requirement: Goal Management (1.2 Scope/Goal Management)
public protocol GoalRepositoryProtocol {
    func createGoal(_ goal: Goal) -> Result<Goal, Error>
    func fetchGoal(id: UUID) -> Result<Goal?, Error>
    func fetchAllGoals() -> Result<[Goal], Error>
    func updateGoal(_ goal: Goal) -> Result<Goal, Error>
    func deleteGoal(id: UUID) -> Result<Void, Error>
}

// Custom errors for repository operations
private enum GoalRepositoryError: LocalizedError {
    case invalidGoal(String)
    case goalNotFound(UUID)
    case persistenceError(Error)
    case contextError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidGoal(let message):
            return "Invalid goal: \(message)"
        case .goalNotFound(let id):
            return "Goal not found with ID: \(id)"
        case .persistenceError(let error):
            return "Persistence error: \(error.localizedDescription)"
        case .contextError(let message):
            return "Context error: \(message)"
        }
    }
}

// Implements requirements:
// - Goal Management (1.2 Scope/Goal Management)
// - Local Data Persistence (4.3.2 Client Storage/iOS)
// - Cross-platform Data Synchronization (1.1 System Overview/Client Applications)
public final class GoalRepository: GoalRepositoryProtocol {
    
    // MARK: - Properties
    
    private let coreDataManager: CoreDataManager
    
    // MARK: - Initialization
    
    public init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - GoalRepositoryProtocol Implementation
    
    public func createGoal(_ goal: Goal) -> Result<Goal, Error> {
        var result: Result<Goal, Error>!
        
        coreDataManager.performBackgroundTask { context in
            do {
                // Create new goal entity
                guard let entity = NSEntityDescription.insertNewObject(
                    forEntityName: "GoalEntity",
                    into: context
                ) as? GoalEntity else {
                    result = .failure(GoalRepositoryError.contextError("Failed to create goal entity"))
                    return
                }
                
                // Update entity with goal data
                entity.update(with: goal)
                
                // Save context
                if self.coreDataManager.saveContext(context) {
                    result = .success(entity.toDomainModel())
                } else {
                    result = .failure(GoalRepositoryError.persistenceError(
                        NSError(domain: "GoalRepository", code: -1, userInfo: nil)
                    ))
                }
            } catch {
                result = .failure(GoalRepositoryError.persistenceError(error))
            }
        }
        
        return result
    }
    
    public func fetchGoal(id: UUID) -> Result<Goal?, Error> {
        var result: Result<Goal?, Error>!
        
        coreDataManager.performBackgroundTask { context in
            do {
                // Create fetch request
                let request = GoalEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                request.fetchLimit = 1
                
                // Execute fetch request
                let goals = try context.fetch(request)
                
                if let goalEntity = goals.first {
                    result = .success(goalEntity.toDomainModel())
                } else {
                    result = .success(nil)
                }
            } catch {
                result = .failure(GoalRepositoryError.persistenceError(error))
            }
        }
        
        return result
    }
    
    public func fetchAllGoals() -> Result<[Goal], Error> {
        var result: Result<[Goal], Error>!
        
        coreDataManager.performBackgroundTask { context in
            do {
                // Create fetch request with sorting
                let request = GoalEntity.fetchRequest()
                request.sortDescriptors = [
                    NSSortDescriptor(key: "targetDate", ascending: true),
                    NSSortDescriptor(key: "name", ascending: true)
                ]
                
                // Execute fetch request
                let goalEntities = try context.fetch(request)
                
                // Convert entities to domain models
                let goals = goalEntities.map { $0.toDomainModel() }
                result = .success(goals)
            } catch {
                result = .failure(GoalRepositoryError.persistenceError(error))
            }
        }
        
        return result
    }
    
    public func updateGoal(_ goal: Goal) -> Result<Goal, Error> {
        var result: Result<Goal, Error>!
        
        coreDataManager.performBackgroundTask { context in
            do {
                // Fetch existing goal entity
                let request = GoalEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", goal.id as CVarArg)
                request.fetchLimit = 1
                
                let goals = try context.fetch(request)
                
                guard let goalEntity = goals.first else {
                    result = .failure(GoalRepositoryError.goalNotFound(goal.id))
                    return
                }
                
                // Update entity with new data
                goalEntity.update(with: goal)
                
                // Save context
                if self.coreDataManager.saveContext(context) {
                    result = .success(goalEntity.toDomainModel())
                } else {
                    result = .failure(GoalRepositoryError.persistenceError(
                        NSError(domain: "GoalRepository", code: -1, userInfo: nil)
                    ))
                }
            } catch {
                result = .failure(GoalRepositoryError.persistenceError(error))
            }
        }
        
        return result
    }
    
    public func deleteGoal(id: UUID) -> Result<Void, Error> {
        var result: Result<Void, Error>!
        
        coreDataManager.performBackgroundTask { context in
            do {
                // Fetch goal entity to delete
                let request = GoalEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                request.fetchLimit = 1
                
                let goals = try context.fetch(request)
                
                guard let goalEntity = goals.first else {
                    result = .failure(GoalRepositoryError.goalNotFound(id))
                    return
                }
                
                // Delete entity
                context.delete(goalEntity)
                
                // Save context
                if self.coreDataManager.saveContext(context) {
                    result = .success(())
                } else {
                    result = .failure(GoalRepositoryError.persistenceError(
                        NSError(domain: "GoalRepository", code: -1, userInfo: nil)
                    ))
                }
            } catch {
                result = .failure(GoalRepositoryError.persistenceError(error))
            }
        }
        
        return result
    }
}