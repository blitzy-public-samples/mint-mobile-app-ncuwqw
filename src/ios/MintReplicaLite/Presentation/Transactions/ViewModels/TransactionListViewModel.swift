// HUMAN TASKS:
// 1. Verify Combine framework is properly linked in project settings
// 2. Ensure minimum iOS deployment target is set to iOS 14.0+
// 3. Configure error tracking service for production monitoring
// 4. Review transaction sync batch size with backend team

// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../../../Common/Protocols/ViewModelType"
import "../../../Domain/Models/Transaction"
import "../../../Domain/UseCases/TransactionsUseCase"

/// ViewModel for managing transaction list view state and user interactions
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking): Transaction search, filtering, and category management
/// - Cross-platform Data Synchronization (1.2 Scope/Account Management): Real-time balance updates
final class TransactionListViewModel: ViewModelType {
    
    // MARK: - Type Definitions
    
    /// Input type representing all possible inputs from the view
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refreshTriggered: AnyPublisher<Void, Never>
        let filterSelected: AnyPublisher<TransactionFilter?, Never>
        let sortSelected: AnyPublisher<TransactionSort?, Never>
    }
    
    /// Output type representing all possible outputs to the view
    struct Output {
        let transactions: AnyPublisher<[Transaction], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<Error?, Never>
    }
    
    // MARK: - Private Properties
    
    private let transactionsUseCase: TransactionsUseCaseProtocol
    private let refreshTrigger = PassthroughSubject<Void, Never>()
    private let filterSubject = CurrentValueSubject<TransactionFilter?, Never>(nil)
    private let sortSubject = CurrentValueSubject<TransactionSort?, Never>(nil)
    private let transactionsSubject = CurrentValueSubject<[Transaction], Never>([])
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = CurrentValueSubject<Error?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with required dependencies
    /// - Parameter transactionsUseCase: Use case for transaction operations
    init(transactionsUseCase: TransactionsUseCaseProtocol) {
        self.transactionsUseCase = transactionsUseCase
    }
    
    // MARK: - ViewModelType Implementation
    
    /// Transforms view inputs into outputs according to MVVM pattern
    /// - Parameter input: The input data and events from the view
    /// - Returns: The transformed output data for view consumption
    func transform(_ input: Input) -> Output {
        // Handle view load event
        input.viewDidLoad
            .sink { [weak self] _ in
                self?.fetchTransactions()
            }
            .store(in: &cancellables)
        
        // Handle refresh trigger
        input.refreshTriggered
            .sink { [weak self] _ in
                self?.syncTransactions()
            }
            .store(in: &cancellables)
        
        // Handle filter selection
        input.filterSelected
            .sink { [weak self] filter in
                self?.filterSubject.send(filter)
                self?.fetchTransactions()
            }
            .store(in: &cancellables)
        
        // Handle sort selection
        input.sortSelected
            .sink { [weak self] sort in
                self?.sortSubject.send(sort)
                self?.fetchTransactions()
            }
            .store(in: &cancellables)
        
        return Output(
            transactions: transactionsSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    
    /// Fetches transactions based on current filter and sort settings
    private func fetchTransactions() {
        isLoadingSubject.send(true)
        errorSubject.send(nil)
        
        let currentFilter = filterSubject.value
        let currentSort = sortSubject.value
        
        transactionsUseCase.getTransactions(filter: currentFilter, sort: currentSort)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error)
                    }
                },
                receiveValue: { [weak self] transactions in
                    self?.transactionsSubject.send(transactions)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Triggers transaction synchronization
    private func syncTransactions() {
        isLoadingSubject.send(true)
        errorSubject.send(nil)
        
        // Get the first account ID from the current transactions
        // In a real implementation, this might come from user selection or app state
        guard let accountId = transactionsSubject.value.first?.accountId else {
            isLoadingSubject.send(false)
            return
        }
        
        transactionsUseCase.syncTransactions(accountId: accountId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error)
                    }
                },
                receiveValue: { [weak self] transactions in
                    self?.transactionsSubject.send(transactions)
                }
            )
            .store(in: &cancellables)
    }
}