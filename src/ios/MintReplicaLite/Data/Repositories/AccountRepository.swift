//
// AccountRepository.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Configure field-level encryption keys in Keychain
// 2. Set up SSL certificate pinning for API client
// 3. Review data retention policies with security team
// 4. Verify Core Data model schema matches AccountEntity

// Foundation framework - iOS 14.0+
import Foundation
// CoreData framework - iOS 14.0+
import CoreData
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../../Domain/Models/Account"
import "../CoreData/Entities/AccountEntity"
import "../CoreData/CoreDataManager"
import "../Network/APIClient"

// MARK: - AccountRepositoryProtocol

/// Protocol defining the interface for account data operations with secure handling
/// Implements Account Management requirement from Section 1.2
protocol AccountRepositoryProtocol {
    func getAccounts() -> AnyPublisher<[Account], Error>
    func getAccount(id: UUID) -> AnyPublisher<Account?, Error>
    func saveAccount(_ account: Account) -> AnyPublisher<Account, Error>
    func deleteAccount(id: UUID) -> AnyPublisher<Void, Error>
    func syncAccounts() -> AnyPublisher<[Account], Error>
}

// MARK: - AccountRepository

/// Thread-safe implementation of AccountRepositoryProtocol handling both local and remote account data operations
/// Implements:
/// - Account Management (Section 1.2): Financial account aggregation with real-time balance updates
/// - Financial Tracking (Section 1.2): Automated transaction import and account balance monitoring
/// - Data Security (Section 2.4): Secure handling and storage of sensitive account information
@objc final class AccountRepository: NSObject {
    
    // MARK: - Properties
    
    private let coreDataManager: CoreDataManager
    private let apiClient: APIClient
    
    // MARK: - Initialization
    
    override init() {
        self.coreDataManager = CoreDataManager.shared
        self.apiClient = APIClient.shared
        super.init()
    }
}

// MARK: - AccountRepositoryProtocol Implementation

extension AccountRepository: AccountRepositoryProtocol {
    
    /// Retrieves all accounts from local storage with secure decryption
    /// Implements Account Management requirement for data access
    func getAccounts() -> AnyPublisher<[Account], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AccountRepository", code: -1)))
                return
            }
            
            self.coreDataManager.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(value: true)
                
                do {
                    let entities = try context.fetch(fetchRequest)
                    let accounts = entities.map { $0.toDomain() }
                    promise(.success(accounts))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Retrieves specific account from local storage with secure decryption
    /// Implements Account Management requirement for individual account access
    func getAccount(id: UUID) -> AnyPublisher<Account?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AccountRepository", code: -1)))
                return
            }
            
            self.coreDataManager.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                
                do {
                    let entity = try context.fetch(fetchRequest).first
                    let account = entity?.toDomain()
                    promise(.success(account))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Saves account to local storage and syncs with server using encryption
    /// Implements:
    /// - Account Management requirement for data persistence
    /// - Data Security requirement for secure storage
    func saveAccount(_ account: Account) -> AnyPublisher<Account, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AccountRepository", code: -1)))
                return
            }
            
            self.coreDataManager.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", account.id as CVarArg)
                
                do {
                    let entity = try context.fetch(fetchRequest).first ?? AccountEntity(context: context)
                    entity.update(from: account)
                    
                    // Sync with server
                    self.apiClient.request(.saveAccount(account), responseType: Account.self)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { updatedAccount in
                                entity.update(from: updatedAccount)
                                if self.coreDataManager.saveContext(context) {
                                    promise(.success(updatedAccount))
                                } else {
                                    promise(.failure(NSError(domain: "AccountRepository", code: -2)))
                                }
                            }
                        )
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Securely deletes account from local storage and server
    /// Implements Data Security requirement for secure data deletion
    func deleteAccount(id: UUID) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AccountRepository", code: -1)))
                return
            }
            
            self.coreDataManager.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                
                do {
                    if let entity = try context.fetch(fetchRequest).first {
                        // Delete from server first
                        self.apiClient.request(.deleteAccount(id), responseType: Void.self)
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        promise(.failure(error))
                                    }
                                },
                                receiveValue: { _ in
                                    // Then delete locally
                                    context.delete(entity)
                                    if self.coreDataManager.saveContext(context) {
                                        promise(.success(()))
                                    } else {
                                        promise(.failure(NSError(domain: "AccountRepository", code: -2)))
                                    }
                                }
                            )
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
    
    /// Synchronizes accounts with remote server using secure TLS 1.3
    /// Implements:
    /// - Account Management requirement for cross-platform synchronization
    /// - Financial Tracking requirement for real-time updates
    func syncAccounts() -> AnyPublisher<[Account], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AccountRepository", code: -1)))
                return
            }
            
            // Fetch latest from server
            self.apiClient.request(.getAccounts, responseType: [Account].self)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { serverAccounts in
                        self.coreDataManager.performBackgroundTask { context in
                            do {
                                // Get current local accounts
                                let fetchRequest: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
                                let localEntities = try context.fetch(fetchRequest)
                                
                                // Create lookup dictionary
                                let localDict = Dictionary(uniqueKeysWithValues: localEntities.map { ($0.id, $0) })
                                
                                // Update or create entities
                                for account in serverAccounts {
                                    if let existingEntity = localDict[account.id] {
                                        existingEntity.update(from: account)
                                    } else {
                                        let newEntity = AccountEntity(context: context)
                                        newEntity.update(from: account)
                                    }
                                }
                                
                                // Delete accounts that no longer exist on server
                                let serverIds = Set(serverAccounts.map { $0.id })
                                let entitiesToDelete = localEntities.filter { !serverIds.contains($0.id) }
                                entitiesToDelete.forEach { context.delete($0) }
                                
                                if self.coreDataManager.saveContext(context) {
                                    promise(.success(serverAccounts))
                                } else {
                                    promise(.failure(NSError(domain: "AccountRepository", code: -2)))
                                }
                            } catch {
                                promise(.failure(error))
                            }
                        }
                    }
                )
        }
        .eraseToAnyPublisher()
    }
}