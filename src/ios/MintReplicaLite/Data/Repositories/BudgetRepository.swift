// HUMAN TASKS:
// 1. Verify Core Data model includes BudgetEntity with all required properties
// 2. Configure API endpoints in APIRouter for budget operations
// 3. Review error handling and logging strategy with team
// 4. Set up background fetch capabilities in project settings

// CoreData framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Internal imports with relative paths
import "../../../Domain/Models/Budget"
import "../../CoreData/Entities/BudgetEntity"
import "../../CoreData/CoreDataManager"
import "../../Network/APIClient"

/// Repository implementation for managing budget data persistence and synchronization
/// Requirements addressed:
/// - Category-based budgeting (1.2 Scope/Budget Management)
/// - Progress monitoring (1.2 Scope/Budget Management)
/// - Local Data Persistence (4.3.2 Client Storage/iOS)
/// - Cross-platform data synchronization (1.2 Scope/Account Management)
@objc final class BudgetRepository {
    
    // MARK: - Properties
    
    private let coreDataManager: CoreDataManager
    private let apiClient: APIClient
    private let mainContext: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init() {
        self.coreDataManager = CoreDataManager.shared
        self.apiClient = APIClient.shared
        self.mainContext = CoreDataManager.shared.mainContext
    }
    
    // MARK: - Public Methods
    
    /// Retrieves a budget by its ID
    /// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
    /// - Parameter id: Budget unique identifier
    /// - Returns: Publisher with optional budget or error
    func getBudget(id: UUID) -> AnyPublisher<Budget?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "BudgetRepository",
                                      code: 4001,
                                      userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"])))
                return
            }
            
            let predicate = NSPredicate(format: "id == %@", id as CVarArg)
            let fetchRequest: NSFetchRequest<BudgetEntity> = BudgetEntity.fetchRequest()
            fetchRequest.predicate = predicate
            
            do {
                let result = try self.mainContext.fetch(fetchRequest)
                let budget = result.first?.toDomain()
                promise(.success(budget))
            } catch {
                promise(.failure(error))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Retrieves all budgets with optional filtering
    /// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
    /// - Parameter predicate: Optional predicate for filtering budgets
    /// - Returns: Publisher with array of budgets or error
    func getAllBudgets(predicate: NSPredicate? = nil) -> AnyPublisher<[Budget], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "BudgetRepository",
                                      code: 4002,
                                      userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"])))
                return
            }
            
            let fetchRequest: NSFetchRequest<BudgetEntity> = BudgetEntity.fetchRequest()
            fetchRequest.predicate = predicate
            
            do {
                let results = try self.mainContext.fetch(fetchRequest)
                let budgets = results.map { $0.toDomain() }
                promise(.success(budgets))
            } catch {
                promise(.failure(error))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Saves a new or updates existing budget
    /// Requirements addressed:
    /// - Category-based budgeting (1.2 Scope/Budget Management)
    /// - Local Data Persistence (4.3.2 Client Storage/iOS)
    /// - Cross-platform data synchronization (1.2 Scope/Account Management)
    /// - Parameter budget: Budget to save or update
    /// - Returns: Publisher with saved budget or error
    func saveBudget(_ budget: Budget) -> AnyPublisher<Budget, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "BudgetRepository",
                                      code: 4003,
                                      userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"])))
                return
            }
            
            self.coreDataManager.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<BudgetEntity> = BudgetEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", budget.id as CVarArg)
                
                do {
                    let results = try context.fetch(fetchRequest)
                    let budgetEntity = results.first ?? BudgetEntity(context: context)
                    budgetEntity.update(from: budget)
                    
                    try context.save()
                    
                    // Sync with remote API
                    self.apiClient.request(.saveBudget(budget), responseType: Budget.self)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { updatedBudget in
                                promise(.success(updatedBudget))
                            }
                        )
                        .cancel()
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Deletes a budget by its ID
    /// Requirements addressed:
    /// - Category-based budgeting (1.2 Scope/Budget Management)
    /// - Local Data Persistence (4.3.2 Client Storage/iOS)
    /// - Cross-platform data synchronization (1.2 Scope/Account Management)
    /// - Parameter id: Budget unique identifier
    /// - Returns: Publisher with success or error
    func deleteBudget(id: UUID) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "BudgetRepository",
                                      code: 4004,
                                      userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"])))
                return
            }
            
            self.coreDataManager.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<BudgetEntity> = BudgetEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                
                do {
                    let results = try context.fetch(fetchRequest)
                    if let budgetEntity = results.first {
                        context.delete(budgetEntity)
                        try context.save()
                        
                        // Sync deletion with remote API
                        self.apiClient.request(.deleteBudget(id), responseType: Void.self)
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        promise(.failure(error))
                                    } else {
                                        promise(.success(()))
                                    }
                                },
                                receiveValue: { _ in }
                            )
                            .cancel()
                    } else {
                        promise(.success(()))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Synchronizes local budgets with remote server
    /// Requirement: Cross-platform data synchronization (1.2 Scope/Account Management)
    /// - Returns: Publisher with success or error
    func syncBudgets() -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "BudgetRepository",
                                      code: 4005,
                                      userInfo: [NSLocalizedDescriptionKey: "Repository deallocated"])))
                return
            }
            
            // Fetch remote budgets
            self.apiClient.request(.getAllBudgets, responseType: [Budget].self)
                .flatMap { remoteBudgets -> AnyPublisher<Void, Error> in
                    return Future { promise in
                        self.coreDataManager.performBackgroundTask { context in
                            let fetchRequest: NSFetchRequest<BudgetEntity> = BudgetEntity.fetchRequest()
                            
                            do {
                                let localBudgets = try context.fetch(fetchRequest)
                                let localBudgetIds = Set(localBudgets.map { $0.id })
                                let remoteBudgetIds = Set(remoteBudgets.map { $0.id })
                                
                                // Delete local budgets not in remote
                                let budgetsToDelete = localBudgets.filter { !remoteBudgetIds.contains($0.id) }
                                budgetsToDelete.forEach { context.delete($0) }
                                
                                // Update or create budgets from remote
                                for remoteBudget in remoteBudgets {
                                    let budgetEntity = localBudgets.first { $0.id == remoteBudget.id } ?? 
                                                     BudgetEntity(context: context)
                                    budgetEntity.update(from: remoteBudget)
                                }
                                
                                try context.save()
                                promise(.success(()))
                            } catch {
                                promise(.failure(error))
                            }
                        }
                    }
                    .eraseToAnyPublisher()
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        } else {
                            promise(.success(()))
                        }
                    },
                    receiveValue: { _ in }
                )
                .cancel()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}