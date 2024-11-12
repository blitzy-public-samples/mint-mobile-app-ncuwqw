//
// SyncService.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Configure background fetch capabilities in project settings
// 2. Review and adjust sync interval for production environment
// 3. Verify network bandwidth usage with performance team
// 4. Set up push notification entitlements for sync notifications

import Foundation // iOS 14.0+
import Combine // iOS 14.0+

// Import relative to current file location
import "../Data/Network/APIClient"
import "../Data/CoreData/CoreDataManager"
import "../Common/Utils/Logger"

/// Service responsible for managing data synchronization between client and server
/// Implements Cross-platform data synchronization requirement from Section 1.2 Scope/Account Management
@objc final class SyncService {
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = SyncService()
    
    /// Publisher for sync completion events
    private let syncCompletedSubject = PassthroughSubject<Void, Never>()
    
    /// Publisher for sync error events
    private let syncErrorSubject = PassthroughSubject<Error, Never>()
    
    /// Interval between automatic sync operations (default: 5 minutes)
    private var syncInterval: TimeInterval
    
    /// Set to store active subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Flag indicating if sync is in progress
    private var isSyncing: Bool
    
    /// Serial queue for sync operations
    private let syncQueue: DispatchQueue
    
    // MARK: - Initialization
    
    private init() {
        self.syncInterval = 300 // 5 minutes
        self.isSyncing = false
        self.syncQueue = DispatchQueue(label: "com.mintreplicalite.sync", qos: .utility)
        
        Logger.shared.log(
            "SyncService initialized",
            level: .info,
            category: .sync
        )
    }
    
    // MARK: - Public Methods
    
    /// Initiates manual sync operation with error handling
    /// Implements Real-time balance updates requirement from Section 1.2 Scope/Account Management
    func startSync() -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "com.mintreplicalite.sync", code: -1, userInfo: [NSLocalizedDescriptionKey: "SyncService instance not available"])))
                return
            }
            
            self.syncQueue.async {
                guard !self.isSyncing else {
                    promise(.failure(NSError(domain: "com.mintreplicalite.sync", code: -2, userInfo: [NSLocalizedDescriptionKey: "Sync already in progress"])))
                    return
                }
                
                self.isSyncing = true
                Logger.shared.log(
                    "Starting manual sync operation",
                    level: .info,
                    category: .sync
                )
                
                self.syncAccounts()
                    .flatMap { _ in self.syncTransactions() }
                    .sink(
                        receiveCompletion: { completion in
                            self.syncQueue.async {
                                self.isSyncing = false
                                
                                switch completion {
                                case .finished:
                                    CoreDataManager.shared.saveContext()
                                    self.syncCompletedSubject.send()
                                    promise(.success(()))
                                    Logger.shared.log(
                                        "Manual sync completed successfully",
                                        level: .info,
                                        category: .sync
                                    )
                                case .failure(let error):
                                    self.syncErrorSubject.send(error)
                                    promise(.failure(error))
                                    Logger.shared.log(
                                        "Manual sync failed: \(error.localizedDescription)",
                                        level: .error,
                                        category: .sync
                                    )
                                }
                            }
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &self.cancellables)
            }
        }.eraseToAnyPublisher()
    }
    
    /// Starts automatic background sync with specified interval
    /// Implements Cross-platform data synchronization requirement from Section 1.2 Scope/Account Management
    func startAutoSync(interval: TimeInterval) {
        syncQueue.async {
            self.syncInterval = interval
            
            Timer.publish(every: interval, on: .main, in: .common)
                .autoconnect()
                .receive(on: self.syncQueue)
                .flatMap { _ in
                    self.startSync()
                        .catch { error -> AnyPublisher<Void, Never> in
                            Logger.shared.log(
                                "Auto-sync failed: \(error.localizedDescription)",
                                level: .error,
                                category: .sync
                            )
                            return Empty().eraseToAnyPublisher()
                        }
                }
                .sink { _ in }
                .store(in: &self.cancellables)
            
            Logger.shared.log(
                "Started auto-sync with interval: \(interval) seconds",
                level: .info,
                category: .sync
            )
        }
    }
    
    /// Stops automatic background sync
    func stopAutoSync() {
        syncQueue.async {
            self.cancellables.removeAll()
            self.isSyncing = false
            
            Logger.shared.log(
                "Stopped auto-sync",
                level: .info,
                category: .sync
            )
        }
    }
}

// MARK: - Private Extensions

private extension SyncService {
    /// Synchronizes account data with server
    /// Implements Real-time balance updates requirement from Section 1.2 Scope/Account Management
    func syncAccounts() -> AnyPublisher<Void, Error> {
        return APIClient.shared.request(
            .getAccounts,
            responseType: AccountSyncResponse.self
        )
        .flatMap { response -> AnyPublisher<Void, Error> in
            Future { promise in
                CoreDataManager.shared.performBackgroundTask { context in
                    do {
                        // Process account updates
                        for accountData in response.accounts {
                            // Update or create account in Core Data
                            let fetchRequest = NSFetchRequest<Account>(entityName: "Account")
                            fetchRequest.predicate = NSPredicate(format: "id == %@", accountData.id)
                            
                            let existingAccount = try context.fetch(fetchRequest).first
                            let account = existingAccount ?? Account(context: context)
                            
                            account.id = accountData.id
                            account.name = accountData.name
                            account.type = accountData.type
                            account.balance = accountData.balance
                            account.lastSyncDate = Date()
                        }
                        
                        try context.save()
                        promise(.success(()))
                        
                        Logger.shared.log(
                            "Account sync completed: \(response.accounts.count) accounts processed",
                            level: .info,
                            category: .sync
                        )
                    } catch {
                        promise(.failure(error))
                        Logger.shared.log(
                            "Account sync failed: \(error.localizedDescription)",
                            level: .error,
                            category: .sync
                        )
                    }
                }
            }.eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    /// Synchronizes transaction data with server
    /// Implements Automated transaction import requirement from Section 1.2 Scope/Financial Tracking
    func syncTransactions() -> AnyPublisher<Void, Error> {
        return APIClient.shared.request(
            .getTransactions,
            responseType: TransactionSyncResponse.self
        )
        .flatMap { response -> AnyPublisher<Void, Error> in
            Future { promise in
                CoreDataManager.shared.performBackgroundTask { context in
                    do {
                        // Process transaction updates
                        for transactionData in response.transactions {
                            // Check for existing transaction
                            let fetchRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
                            fetchRequest.predicate = NSPredicate(format: "id == %@", transactionData.id)
                            
                            let existingTransaction = try context.fetch(fetchRequest).first
                            
                            // Skip if transaction exists and hasn't changed
                            if let existing = existingTransaction,
                               existing.modificationDate == transactionData.modificationDate {
                                continue
                            }
                            
                            // Update or create transaction
                            let transaction = existingTransaction ?? Transaction(context: context)
                            transaction.id = transactionData.id
                            transaction.amount = transactionData.amount
                            transaction.date = transactionData.date
                            transaction.description = transactionData.description
                            transaction.category = transactionData.category
                            transaction.accountId = transactionData.accountId
                            transaction.modificationDate = transactionData.modificationDate
                        }
                        
                        try context.save()
                        promise(.success(()))
                        
                        Logger.shared.log(
                            "Transaction sync completed: \(response.transactions.count) transactions processed",
                            level: .info,
                            category: .sync
                        )
                    } catch {
                        promise(.failure(error))
                        Logger.shared.log(
                            "Transaction sync failed: \(error.localizedDescription)",
                            level: .error,
                            category: .sync
                        )
                    }
                }
            }.eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}