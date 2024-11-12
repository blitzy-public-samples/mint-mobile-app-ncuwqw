// HUMAN TASKS:
// 1. Configure field-level encryption keys in Keychain for sensitive transaction data
// 2. Review and adjust transaction sync batch size for optimal performance
// 3. Verify conflict resolution strategy with product team
// 4. Set up database indices for transaction queries in Core Data model

// Foundation framework - iOS 14.0+
import Foundation
// CoreData framework - iOS 14.0+
import CoreData
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../../../Domain/Models/Transaction"
import "../CoreData/Entities/TransactionEntity"
import "../CoreData/CoreDataManager"
import "../Network/APIClient"

/// Protocol defining the transaction repository interface with secure data handling
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking)
/// - Transaction Data Security (6.2.2 Sensitive Data Handling)
public protocol TransactionRepositoryProtocol {
    /// Retrieves transactions with optional filtering and secure decryption
    func getTransactions(
        startDate: Date?,
        endDate: Date?,
        accountId: UUID?,
        categoryId: UUID?
    ) -> AnyPublisher<[Transaction], Error>
    
    /// Retrieves a specific transaction by ID with secure decryption
    func getTransaction(id: UUID) -> AnyPublisher<Transaction?, Error>
    
    /// Saves a new or updated transaction with secure encryption
    func saveTransaction(_ transaction: Transaction) -> AnyPublisher<Transaction, Error>
    
    /// Securely deletes a transaction
    func deleteTransaction(id: UUID) -> AnyPublisher<Void, Error>
    
    /// Synchronizes local transactions with remote server using secure transport
    func syncTransactions(accountId: UUID) -> AnyPublisher<[Transaction], Error>
}

/// Thread-safe implementation of TransactionRepositoryProtocol handling secure transaction data management
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking): Transaction management and persistence
/// - Cross-platform Data Synchronization (1.2 Scope/Account Management): Real-time sync
/// - Transaction Data Security (6.2.2 Sensitive Data Handling): Secure data handling
final class TransactionRepository: TransactionRepositoryProtocol {
    
    // MARK: - Properties
    
    private let coreDataManager: CoreDataManager
    private let apiClient: APIClient
    private let serialQueue: DispatchQueue
    
    // MARK: - Initialization
    
    init() {
        self.coreDataManager = CoreDataManager.shared
        self.apiClient = APIClient.shared
        self.serialQueue = DispatchQueue(label: "com.mintreplicalite.transactionrepository")
    }
    
    // MARK: - TransactionRepositoryProtocol Implementation
    
    func getTransactions(
        startDate: Date?,
        endDate: Date?,
        accountId: UUID?,
        categoryId: UUID?
    ) -> AnyPublisher<[Transaction], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "TransactionRepository", code: -1)))
                return
            }
            
            // Build predicate for filtering
            var predicates: [NSPredicate] = []
            
            if let startDate = startDate {
                predicates.append(NSPredicate(format: "date >= %@", startDate as NSDate))
            }
            
            if let endDate = endDate {
                predicates.append(NSPredicate(format: "date <= %@", endDate as NSDate))
            }
            
            if let accountId = accountId {
                predicates.append(NSPredicate(format: "accountId == %@", accountId as CVarArg))
            }
            
            if let categoryId = categoryId {
                predicates.append(NSPredicate(format: "categoryId == %@", categoryId as CVarArg))
            }
            
            let finalPredicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            
            // Perform fetch on background context
            self.coreDataManager.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
                fetchRequest.predicate = finalPredicate
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                
                do {
                    let entities = try context.fetch(fetchRequest)
                    let transactions = entities.map { $0.toDomain() }
                    promise(.success(transactions))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTransaction(id: UUID) -> AnyPublisher<Transaction?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "TransactionRepository", code: -1)))
                return
            }
            
            self.coreDataManager.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                fetchRequest.fetchLimit = 1
                
                do {
                    let entity = try context.fetch(fetchRequest).first
                    let transaction = entity?.toDomain()
                    promise(.success(transaction))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveTransaction(_ transaction: Transaction) -> AnyPublisher<Transaction, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "TransactionRepository", code: -1)))
                return
            }
            
            // Save to local storage
            self.coreDataManager.performBackgroundTask { context in
                let entity = TransactionEntity.fromDomain(transaction, context: context)
                
                do {
                    try context.save()
                    
                    // Upload to API
                    self.uploadTransaction(transaction)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { _ in
                                promise(.success(transaction))
                            }
                        )
                        .cancel()
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteTransaction(id: UUID) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "TransactionRepository", code: -1)))
                return
            }
            
            self.coreDataManager.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                
                do {
                    if let entity = try context.fetch(fetchRequest).first {
                        context.delete(entity)
                        try context.save()
                        
                        // Delete from API
                        self.deleteTransactionFromAPI(id)
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        promise(.failure(error))
                                    }
                                },
                                receiveValue: {
                                    promise(.success(()))
                                }
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
        .eraseToAnyPublisher()
    }
    
    func syncTransactions(accountId: UUID) -> AnyPublisher<[Transaction], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "TransactionRepository", code: -1)))
                return
            }
            
            // Fetch remote transactions
            self.fetchRemoteTransactions(accountId: accountId)
                .flatMap { remoteTransactions -> AnyPublisher<[Transaction], Error> in
                    // Merge with local transactions
                    return self.mergeTransactions(remoteTransactions, accountId: accountId)
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { mergedTransactions in
                        promise(.success(mergedTransactions))
                    }
                )
                .cancel()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func uploadTransaction(_ transaction: Transaction) -> AnyPublisher<Void, Error> {
        // Implement API client request for transaction upload
        return apiClient.request(.saveTransaction(transaction), responseType: Void.self)
    }
    
    private func deleteTransactionFromAPI(_ id: UUID) -> AnyPublisher<Void, Error> {
        // Implement API client request for transaction deletion
        return apiClient.request(.deleteTransaction(id), responseType: Void.self)
    }
    
    private func fetchRemoteTransactions(accountId: UUID) -> AnyPublisher<[Transaction], Error> {
        // Implement API client request for fetching remote transactions
        return apiClient.request(.getTransactions(accountId: accountId), responseType: [Transaction].self)
    }
    
    private func mergeTransactions(_ remoteTransactions: [Transaction], accountId: UUID) -> AnyPublisher<[Transaction], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "TransactionRepository", code: -1)))
                return
            }
            
            self.coreDataManager.performBackgroundTask { context in
                // Fetch local transactions
                let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "accountId == %@", accountId as CVarArg)
                
                do {
                    let localEntities = try context.fetch(fetchRequest)
                    let localTransactions = localEntities.map { $0.toDomain() }
                    
                    // Merge logic - prefer remote version for conflicts
                    var mergedTransactions: [Transaction] = []
                    var processedIds: Set<UUID> = []
                    
                    // Add remote transactions
                    for remote in remoteTransactions {
                        let entity = TransactionEntity.fromDomain(remote, context: context)
                        mergedTransactions.append(remote)
                        processedIds.insert(remote.id)
                    }
                    
                    // Add local-only transactions
                    for local in localTransactions where !processedIds.contains(local.id) {
                        mergedTransactions.append(local)
                    }
                    
                    try context.save()
                    promise(.success(mergedTransactions))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}