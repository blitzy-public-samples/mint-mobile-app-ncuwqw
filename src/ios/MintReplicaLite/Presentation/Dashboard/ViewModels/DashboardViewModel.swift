//
// DashboardViewModel.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify Combine subscription cleanup in production environment
// 2. Review memory management for large account datasets
// 3. Configure refresh interval settings in production
// 4. Set up monitoring for dashboard data sync performance

// Third-party Dependencies:
// - Foundation (iOS 14.0+)
// - Combine (iOS 14.0+)

import Foundation
import Combine

// Relative imports
import "../../../Common/Protocols/ViewModelType"
import "../../../Domain/Models/Account"
import "../../../Domain/UseCases/AccountsUseCase"
import "../../../Domain/UseCases/BudgetUseCase"
import "../../../Domain/UseCases/TransactionsUseCase"

/// Input data structure for dashboard view model
struct Input {
    /// Publisher for triggering dashboard data refresh
    let refreshTrigger: AnyPublisher<Void, Never>
}

/// Output data structure for dashboard view model
struct Output {
    /// Publisher providing updated account list
    let accounts: AnyPublisher<[Account], Never>
    /// Publisher providing calculated net worth
    let netWorth: AnyPublisher<Decimal, Never>
    /// Publisher providing recent transactions
    let recentTransactions: AnyPublisher<[Transaction], Never>
    /// Publisher providing budget progress data
    let budgetProgress: AnyPublisher<[(Budget, Double)], Never>
}

/// ViewModel implementation for the Dashboard screen using MVVM architecture with Combine
/// Requirements addressed:
/// - Account Management (1.2 Scope/Account Management): Real-time balance updates and account aggregation
/// - Financial Tracking (1.2 Scope/Financial Tracking): Transaction monitoring and category management
/// - Budget Management (1.2 Scope/Budget Management): Budget progress monitoring and alerts
final class DashboardViewModel: ViewModelType {
    
    // MARK: - Private Properties
    
    private let accountsUseCase: AccountsUseCase
    private let budgetUseCase: BudgetUseCase
    private let transactionsUseCase: TransactionsUseCase
    
    private let refreshTrigger = PassthroughSubject<Void, Never>()
    private let accounts = CurrentValueSubject<[Account], Never>([])
    private let recentTransactions = CurrentValueSubject<[Transaction], Never>([])
    private let budgetProgress = CurrentValueSubject<[(Budget, Double)], Never>([])
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes dashboard view model with required use cases
    /// - Parameters:
    ///   - accountsUseCase: Use case for account management
    ///   - budgetUseCase: Use case for budget management
    ///   - transactionsUseCase: Use case for transaction management
    init(accountsUseCase: AccountsUseCase,
         budgetUseCase: BudgetUseCase,
         transactionsUseCase: TransactionsUseCase) {
        self.accountsUseCase = accountsUseCase
        self.budgetUseCase = budgetUseCase
        self.transactionsUseCase = transactionsUseCase
        
        // Set up initial data load
        refreshDashboard()
    }
    
    // MARK: - ViewModelType Implementation
    
    /// Transforms view inputs into outputs according to MVVM pattern
    /// - Parameter input: Input data and events from view
    /// - Returns: Transformed data streams for view consumption
    func transform(_ input: Input) -> Output {
        // Set up refresh trigger subscription
        input.refreshTrigger
            .sink { [weak self] _ in
                self?.refreshDashboard()
            }
            .store(in: &cancellables)
        
        // Transform account data
        let accountsPublisher = accounts.asAnyPublisher()
        
        // Calculate net worth from accounts
        let netWorthPublisher = accounts
            .map { [weak self] _ in
                self?.calculateNetWorth() ?? Decimal.zero
            }
            .eraseToAnyPublisher()
        
        // Transform recent transactions
        let transactionsPublisher = recentTransactions
            .eraseToAnyPublisher()
        
        // Transform budget progress
        let budgetProgressPublisher = budgetProgress
            .eraseToAnyPublisher()
        
        return Output(
            accounts: accountsPublisher,
            netWorth: netWorthPublisher,
            recentTransactions: transactionsPublisher,
            budgetProgress: budgetProgressPublisher
        )
    }
    
    // MARK: - Public Methods
    
    /// Triggers a refresh of all dashboard data
    /// Requirements addressed:
    /// - Account Management: Real-time balance updates
    /// - Financial Tracking: Transaction monitoring
    /// - Budget Management: Progress monitoring
    func refreshDashboard() {
        // Refresh accounts
        accountsUseCase.syncAccounts()
            .catch { error -> AnyPublisher<[Account], Never> in
                print("Error syncing accounts: \(error)")
                return Just([]).eraseToAnyPublisher()
            }
            .sink { [weak self] syncedAccounts in
                self?.accounts.send(syncedAccounts)
            }
            .store(in: &cancellables)
        
        // Fetch recent transactions
        let transactionFilter = TransactionFilter(
            dateRange: TransactionFilter.DateRange(
                start: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
                end: Date()
            ),
            amountRange: nil,
            accountId: nil,
            categoryId: nil,
            types: nil,
            status: nil
        )
        
        transactionsUseCase.getTransactions(filter: transactionFilter, sort: nil)
            .catch { error -> AnyPublisher<[Transaction], Never> in
                print("Error fetching transactions: \(error)")
                return Just([]).eraseToAnyPublisher()
            }
            .sink { [weak self] transactions in
                self?.recentTransactions.send(transactions)
            }
            .store(in: &cancellables)
        
        // Fetch budget progress
        budgetUseCase.getAllBudgets(period: .monthly)
            .flatMap { budgets -> AnyPublisher<[(Budget, Double)], Error> in
                let progressPublishers = budgets.map { budget in
                    self.budgetUseCase.getBudgetProgress(budgetId: budget.id)
                        .map { progress, _ in
                            return (budget, progress)
                        }
                }
                return Publishers.MergeMany(progressPublishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .catch { error -> AnyPublisher<[(Budget, Double)], Never> in
                print("Error fetching budget progress: \(error)")
                return Just([]).eraseToAnyPublisher()
            }
            .sink { [weak self] progress in
                self?.budgetProgress.send(progress)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    /// Calculates total net worth from accounts
    /// Requirement addressed: Account Management - Real-time balance updates
    /// - Returns: Total net worth value
    private func calculateNetWorth() -> Decimal {
        return accounts.value
            .filter { $0.isActive }
            .reduce(Decimal.zero) { total, account in
                switch account.type {
                case .credit, .loan:
                    return total - account.balance
                default:
                    return total + account.balance
                }
            }
    }
}