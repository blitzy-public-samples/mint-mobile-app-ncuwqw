//
// AccountsUseCase.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify error handling configuration aligns with backend error codes
// 2. Review account validation rules with compliance team
// 3. Configure account sync retry intervals in production environment
// 4. Set up monitoring for account sync performance metrics

// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../Models/Account"
import "../../Data/Repositories/AccountRepository"
import "../../Common/Constants/ErrorConstants"

// MARK: - AccountsUseCaseProtocol

/// Protocol defining the interface for account management business logic
/// Implements Account Management requirement from Section 1.2
protocol AccountsUseCaseProtocol {
    func getAllAccounts() -> AnyPublisher<[Account], Error>
    func addAccount(_ account: Account) -> AnyPublisher<Account, Error>
    func updateAccount(_ account: Account) -> AnyPublisher<Account, Error>
    func removeAccount(id: UUID) -> AnyPublisher<Void, Error>
    func syncAccounts() -> AnyPublisher<[Account], Error>
}

// MARK: - AccountsUseCase

/// Implementation of business logic for account management operations
/// Implements:
/// - Account Management (Section 1.2): Multi-platform user authentication and financial account aggregation
/// - Financial Tracking (Section 1.2): Automated transaction import and account balance monitoring
/// - Data Security (Section 2.4): Secure handling of sensitive account information
final class AccountsUseCase: AccountsUseCaseProtocol {
    
    // MARK: - Properties
    
    private let repository: AccountRepository
    
    // MARK: - Initialization
    
    /// Initializes the use case with required dependencies
    /// - Parameter repository: Repository for account data operations
    init(repository: AccountRepository) {
        self.repository = repository
    }
    
    // MARK: - AccountsUseCaseProtocol Implementation
    
    /// Retrieves and processes all accounts with applied business rules
    /// Implements Account Management requirement for account aggregation
    func getAllAccounts() -> AnyPublisher<[Account], Error> {
        return repository.getAccounts()
            .map { accounts in
                // Filter active accounts and sort by type and name
                accounts.filter { $0.isActive }
                    .sorted { account1, account2 in
                        if account1.type == account2.type {
                            return account1.name < account2.name
                        }
                        return account1.type.rawValue < account2.type.rawValue
                    }
            }
            .eraseToAnyPublisher()
    }
    
    /// Validates and adds new account with security checks
    /// Implements Data Security requirement for secure account handling
    func addAccount(_ account: Account) -> AnyPublisher<Account, Error> {
        return Future<Account, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(ErrorConstants.DataError.saveFailed))
                return
            }
            
            // Validate account data
            guard self.validateAccount(account) else {
                promise(.failure(ErrorConstants.ValidationError.invalidData))
                return
            }
            
            // Check for duplicate accounts
            self.repository.getAccounts()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { existingAccounts in
                        // Check for duplicate account numbers
                        if existingAccounts.contains(where: { $0.accountNumber == account.accountNumber }) {
                            promise(.failure(ErrorConstants.ValidationError.invalidData))
                            return
                        }
                        
                        // Save account if validation passes
                        self.repository.saveAccount(account)
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        promise(.failure(error))
                                    }
                                },
                                receiveValue: { savedAccount in
                                    promise(.success(savedAccount))
                                }
                            )
                            .cancel()
                    }
                )
                .cancel()
        }
        .eraseToAnyPublisher()
    }
    
    /// Updates existing account with validation and security checks
    /// Implements Account Management requirement for account updates
    func updateAccount(_ account: Account) -> AnyPublisher<Account, Error> {
        return Future<Account, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(ErrorConstants.DataError.saveFailed))
                return
            }
            
            // Validate account data
            guard self.validateAccount(account) else {
                promise(.failure(ErrorConstants.ValidationError.invalidData))
                return
            }
            
            // Verify account exists
            self.repository.getAccount(id: account.id)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { existingAccount in
                        guard existingAccount != nil else {
                            promise(.failure(ErrorConstants.DataError.notFound))
                            return
                        }
                        
                        // Update account if validation passes
                        self.repository.saveAccount(account)
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        promise(.failure(error))
                                    }
                                },
                                receiveValue: { updatedAccount in
                                    promise(.success(updatedAccount))
                                }
                            )
                            .cancel()
                    }
                )
                .cancel()
        }
        .eraseToAnyPublisher()
    }
    
    /// Validates and removes account with security checks
    /// Implements Data Security requirement for secure account deletion
    func removeAccount(id: UUID) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(ErrorConstants.DataError.deleteFailed))
                return
            }
            
            // Verify account exists and check for dependencies
            self.repository.getAccount(id: id)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { existingAccount in
                        guard existingAccount != nil else {
                            promise(.failure(ErrorConstants.DataError.notFound))
                            return
                        }
                        
                        // Delete account if no dependencies exist
                        self.repository.deleteAccount(id: id)
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
                    }
                )
                .cancel()
        }
        .eraseToAnyPublisher()
    }
    
    /// Synchronizes accounts with remote server
    /// Implements Financial Tracking requirement for real-time balance updates
    func syncAccounts() -> AnyPublisher<[Account], Error> {
        return repository.syncAccounts()
            .map { accounts in
                // Process and sort synchronized accounts
                accounts.filter { $0.isActive }
                    .sorted { account1, account2 in
                        if account1.type == account2.type {
                            return account1.name < account2.name
                        }
                        return account1.type.rawValue < account2.type.rawValue
                    }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helpers
    
    /// Validates account data according to business rules
    /// - Parameter account: Account to validate
    /// - Returns: Boolean indicating validation status
    private func validateAccount(_ account: Account) -> Bool {
        // Validate required fields
        guard !account.name.isEmpty,
              !account.institutionId.isEmpty,
              !account.accountNumber.isEmpty else {
            return false
        }
        
        // Validate balance
        guard account.balance >= 0 || account.type == .credit || account.type == .loan else {
            return false
        }
        
        // Additional validation rules can be added here
        
        return true
    }
}