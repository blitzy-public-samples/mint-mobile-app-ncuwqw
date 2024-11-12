// HUMAN TASKS:
// 1. Review transaction sync batch size configuration with backend team
// 2. Verify transaction amount validation rules with financial compliance
// 3. Configure error tracking for transaction processing failures
// 4. Set up monitoring for transaction sync performance metrics

// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../Models/Transaction"
import "../../Data/Repositories/TransactionRepository"

/// Protocol defining the transaction use case interface with secure data handling
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking): Transaction management and filtering
public protocol TransactionsUseCaseProtocol {
    /// Retrieves transactions with optional filtering and sorting
    func getTransactions(filter: TransactionFilter?, sort: TransactionSort?) -> AnyPublisher<[Transaction], Error>
    
    /// Creates a new transaction with validation and secure handling
    func createTransaction(accountId: UUID, amount: Decimal, description: String, type: TransactionType, categoryId: UUID?) -> AnyPublisher<Transaction, Error>
    
    /// Updates an existing transaction with validation
    func updateTransaction(_ transaction: Transaction) -> AnyPublisher<Transaction, Error>
    
    /// Synchronizes transactions for an account securely
    func syncTransactions(accountId: UUID) -> AnyPublisher<[Transaction], Error>
}

/// Thread-safe implementation of TransactionsUseCaseProtocol providing transaction business logic
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking): Automated transaction import and category management
/// - Cross-platform Data Synchronization (1.2 Scope/Account Management): Real-time balance updates
public final class TransactionsUseCase: TransactionsUseCaseProtocol {
    // MARK: - Properties
    
    private let repository: TransactionRepositoryProtocol
    private let queue = DispatchQueue(label: "com.mintreplicalite.transactionsusecase", qos: .userInitiated)
    
    // MARK: - Initialization
    
    /// Initializes use case with repository dependency
    /// - Parameter repository: Repository implementation for transaction data operations
    public init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - TransactionsUseCaseProtocol Implementation
    
    /// Retrieves and processes transactions based on filters securely
    /// - Parameters:
    ///   - filter: Optional filter criteria for transactions
    ///   - sort: Optional sorting preferences
    /// - Returns: Publisher with filtered and sorted transactions
    public func getTransactions(filter: TransactionFilter?, sort: TransactionSort?) -> AnyPublisher<[Transaction], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "TransactionsUseCase", code: -1)))
                return
            }
            
            // Extract filter parameters
            let startDate = filter?.dateRange?.start
            let endDate = filter?.dateRange?.end
            let accountId = filter?.accountId
            let categoryId = filter?.categoryId
            
            // Fetch transactions from repository
            self.repository.getTransactions(
                startDate: startDate,
                endDate: endDate,
                accountId: accountId,
                categoryId: categoryId
            )
            .receive(on: self.queue)
            .map { transactions -> [Transaction] in
                // Apply additional filtering
                var filtered = transactions
                
                if let minAmount = filter?.amountRange?.min {
                    filtered = filtered.filter { $0.amount >= minAmount }
                }
                
                if let maxAmount = filter?.amountRange?.max {
                    filtered = filtered.filter { $0.amount <= maxAmount }
                }
                
                if let types = filter?.types {
                    filtered = filtered.filter { types.contains($0.type) }
                }
                
                if let status = filter?.status {
                    filtered = filtered.filter { $0.status == status }
                }
                
                // Apply sorting
                if let sort = sort {
                    filtered.sort { t1, t2 in
                        switch sort.criteria {
                        case .date:
                            return sort.ascending ? t1.date < t2.date : t1.date > t2.date
                        case .amount:
                            return sort.ascending ? t1.amount < t2.amount : t1.amount > t2.amount
                        case .description:
                            return sort.ascending ? t1.description < t2.description : t1.description > t2.description
                        }
                    }
                }
                
                return filtered
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                },
                receiveValue: { transactions in
                    promise(.success(transactions))
                }
            )
            .cancel()
        }
        .eraseToAnyPublisher()
    }
    
    /// Creates and validates a new transaction with secure handling
    /// - Parameters:
    ///   - accountId: ID of the account for the transaction
    ///   - amount: Transaction amount
    ///   - description: Transaction description
    ///   - type: Type of transaction
    ///   - categoryId: Optional category ID
    /// - Returns: Publisher with created transaction
    public func createTransaction(
        accountId: UUID,
        amount: Decimal,
        description: String,
        type: TransactionType,
        categoryId: UUID?
    ) -> AnyPublisher<Transaction, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "TransactionsUseCase", code: -1)))
                return
            }
            
            // Validate input parameters
            guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                promise(.failure(NSError(domain: "TransactionsUseCase", code: 3001, userInfo: [
                    NSLocalizedDescriptionKey: "Transaction description cannot be empty"
                ])))
                return
            }
            
            guard amount != 0 else {
                promise(.failure(NSError(domain: "TransactionsUseCase", code: 3002, userInfo: [
                    NSLocalizedDescriptionKey: "Transaction amount cannot be zero"
                ])))
                return
            }
            
            // Create new transaction
            let transaction = Transaction(
                id: UUID(),
                accountId: accountId,
                amount: amount,
                description: description,
                type: type
            )
            
            // Set category if provided
            if let categoryId = categoryId {
                transaction.updateCategory(categoryId)
            }
            
            // Save transaction
            self.repository.saveTransaction(transaction)
                .receive(on: self.queue)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { savedTransaction in
                        promise(.success(savedTransaction))
                    }
                )
                .cancel()
        }
        .eraseToAnyPublisher()
    }
    
    /// Updates transaction with validation and secure handling
    /// - Parameter transaction: Transaction to update
    /// - Returns: Publisher with updated transaction
    public func updateTransaction(_ transaction: Transaction) -> AnyPublisher<Transaction, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "TransactionsUseCase", code: -1)))
                return
            }
            
            // Validate transaction status
            guard transaction.status != .cancelled else {
                promise(.failure(NSError(domain: "TransactionsUseCase", code: 3003, userInfo: [
                    NSLocalizedDescriptionKey: "Cannot update cancelled transaction"
                ])))
                return
            }
            
            // Update transaction
            self.repository.saveTransaction(transaction)
                .receive(on: self.queue)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { updatedTransaction in
                        promise(.success(updatedTransaction))
                    }
                )
                .cancel()
        }
        .eraseToAnyPublisher()
    }
    
    /// Initiates secure transaction synchronization
    /// - Parameter accountId: ID of the account to sync
    /// - Returns: Publisher with synced transactions
    public func syncTransactions(accountId: UUID) -> AnyPublisher<[Transaction], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "TransactionsUseCase", code: -1)))
                return
            }
            
            // Trigger repository sync
            self.repository.syncTransactions(accountId: accountId)
                .receive(on: self.queue)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { syncedTransactions in
                        promise(.success(syncedTransactions))
                    }
                )
                .cancel()
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

/// Filter criteria for transaction queries
public struct TransactionFilter {
    let dateRange: DateRange?
    let amountRange: AmountRange?
    let accountId: UUID?
    let categoryId: UUID?
    let types: Set<TransactionType>?
    let status: TransactionStatus?
    
    public struct DateRange {
        let start: Date?
        let end: Date?
    }
    
    public struct AmountRange {
        let min: Decimal?
        let max: Decimal?
    }
}

/// Sorting options for transaction queries
public struct TransactionSort {
    let criteria: Criteria
    let ascending: Bool
    
    public enum Criteria {
        case date
        case amount
        case description
    }
}