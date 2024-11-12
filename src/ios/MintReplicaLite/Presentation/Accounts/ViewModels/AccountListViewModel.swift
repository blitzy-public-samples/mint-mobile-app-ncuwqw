//
// AccountListViewModel.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Configure error handling and retry policies for account sync operations
// 2. Set up analytics tracking for account list interactions
// 3. Review memory management and subscription cleanup in production
// 4. Verify accessibility labels and identifiers are properly set

// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../../../Domain/Models/Account"
import "../../../Domain/UseCases/AccountsUseCase"
import "../../../Common/Protocols/ViewModelType"

// MARK: - AccountListViewModelInput

/// Input events that the view model can handle
enum AccountListViewModelInput {
    case viewDidLoad
    case refresh
    case deleteAccount(UUID)
}

// MARK: - AccountListViewModelOutput

/// Output states that the view can consume
enum AccountListViewModelOutput {
    case loading(Bool)
    case accounts([Account])
    case error(Error)
}

// MARK: - AccountListViewModel

/// ViewModel implementation for the account list screen using MVVM pattern
/// Implements:
/// - Account Management (Section 1.2): Financial account aggregation with real-time updates
/// - Financial Tracking (Section 1.2): Account balance monitoring
/// - Client Applications Architecture (Section 2.2.1): MVVM implementation
final class AccountListViewModel: ViewModelType {
    
    // MARK: - Properties
    
    private let accountsUseCase: AccountsUseCaseProtocol
    private let refreshTrigger = PassthroughSubject<Void, Never>()
    private let deleteAccountTrigger = PassthroughSubject<UUID, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private let isLoading = CurrentValueSubject<Bool, Never>(false)
    private let accounts = CurrentValueSubject<[Account], Never>([])
    private let error = CurrentValueSubject<Error?, Never>(nil)
    
    // MARK: - Initialization
    
    /// Initializes the view model with required dependencies
    /// - Parameter accountsUseCase: Use case for account operations
    init(accountsUseCase: AccountsUseCaseProtocol) {
        self.accountsUseCase = accountsUseCase
    }
    
    // MARK: - ViewModelType Implementation
    
    /// Transforms view inputs into outputs using Combine
    /// Implements Account Management requirement for account data presentation
    func transform(_ input: AccountListViewModelInput) -> AccountListViewModelOutput {
        setupBindings(for: input)
        
        return handleOutput()
    }
    
    // MARK: - Private Methods
    
    /// Sets up data bindings based on input events
    private func setupBindings(for input: AccountListViewModelInput) {
        switch input {
        case .viewDidLoad:
            refreshAccounts()
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.error.send(error)
                        }
                    },
                    receiveValue: { [weak self] accounts in
                        self?.accounts.send(accounts)
                    }
                )
                .store(in: &cancellables)
            
        case .refresh:
            refreshTrigger
                .flatMap { [weak self] _ -> AnyPublisher<[Account], Error> in
                    guard let self = self else {
                        return Fail(error: NSError(domain: "AccountListViewModel", code: -1, userInfo: nil))
                            .eraseToAnyPublisher()
                    }
                    return self.refreshAccounts()
                }
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.error.send(error)
                        }
                    },
                    receiveValue: { [weak self] accounts in
                        self?.accounts.send(accounts)
                    }
                )
                .store(in: &cancellables)
            
        case .deleteAccount(let accountId):
            deleteAccountTrigger
                .flatMap { [weak self] id -> AnyPublisher<Void, Error> in
                    guard let self = self else {
                        return Fail(error: NSError(domain: "AccountListViewModel", code: -1, userInfo: nil))
                            .eraseToAnyPublisher()
                    }
                    return self.deleteAccount(accountId: id)
                }
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.error.send(error)
                        }
                    },
                    receiveValue: { [weak self] _ in
                        self?.refreshTrigger.send()
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    /// Handles output state transformations
    private func handleOutput() -> AccountListViewModelOutput {
        // Combine latest values from state subjects
        Publishers.CombineLatest3(isLoading, accounts, error)
            .map { isLoading, accounts, error -> AccountListViewModelOutput in
                if let error = error {
                    return .error(error)
                }
                if isLoading {
                    return .loading(true)
                }
                return .accounts(accounts)
            }
            .eraseToAnyPublisher()
            .sink { output in
                // Handle output state
            }
            .store(in: &cancellables)
        
        return .loading(false)
    }
    
    /// Refreshes account data through use case
    /// Implements Financial Tracking requirement for balance monitoring
    private func refreshAccounts() -> AnyPublisher<[Account], Error> {
        isLoading.send(true)
        
        return accountsUseCase.syncAccounts()
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.isLoading.send(false)
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// Handles account deletion
    /// Implements Account Management requirement for account operations
    private func deleteAccount(accountId: UUID) -> AnyPublisher<Void, Error> {
        isLoading.send(true)
        
        return accountsUseCase.removeAccount(id: accountId)
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.isLoading.send(false)
                }
            )
            .eraseToAnyPublisher()
    }
}