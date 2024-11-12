// HUMAN TASKS:
// 1. Verify Combine framework is properly linked in project settings
// 2. Ensure minimum iOS deployment target is set to iOS 14.0+
// 3. Review error message localization with the team

// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Internal imports with relative paths
import "../../../Common/Protocols/ViewModelType"
import "../../../Domain/Models/Budget"
import "../../../Domain/UseCases/BudgetUseCase"

/// View model implementing presentation logic for budget list screen with reactive data flow
/// Requirements addressed:
/// - Category-based budgeting (1.2 Scope/Budget Management): Budget list management and filtering
/// - Progress monitoring (1.2 Scope/Budget Management): Budget progress tracking and updates
@objc final class BudgetListViewModel: NSObject, ViewModelType {
    
    // MARK: - Types
    
    struct Input {
        /// Trigger to load initial data when view appears
        let viewDidLoad: AnyPublisher<Void, Never>
        /// Selected period filter for budgets
        let periodSelected: AnyPublisher<String?, Never>
        /// Budget deletion request with budget ID
        let deleteBudget: AnyPublisher<UUID, Never>
    }
    
    struct Output {
        /// Current list of budgets
        let budgets: AnyPublisher<[Budget], Never>
        /// Loading state indicator
        let isLoading: AnyPublisher<Bool, Never>
        /// Error messages for user display
        let error: AnyPublisher<String?, Never>
    }
    
    // MARK: - Properties
    
    private let budgetUseCase: BudgetUseCase
    private let budgets = CurrentValueSubject<[Budget], Never>([])
    private let isLoading = CurrentValueSubject<Bool, Never>(false)
    private let error = CurrentValueSubject<String?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes view model with required dependencies
    /// - Parameter budgetUseCase: Use case for budget management operations
    init(budgetUseCase: BudgetUseCase) {
        self.budgetUseCase = budgetUseCase
        super.init()
    }
    
    // MARK: - ViewModelType Implementation
    
    /// Transforms view inputs into reactive outputs
    /// - Parameter input: Combined view input publishers
    /// - Returns: Combined output publishers for view updates
    func transform(_ input: Input) -> Output {
        // Handle view load event
        input.viewDidLoad
            .sink { [weak self] _ in
                self?.loadBudgets(period: nil)
            }
            .store(in: &cancellables)
        
        // Handle period selection
        input.periodSelected
            .sink { [weak self] periodString in
                let period: BudgetPeriod?
                if let periodStr = periodString {
                    period = BudgetPeriod(rawValue: periodStr)
                } else {
                    period = nil
                }
                self?.loadBudgets(period: periodString)
            }
            .store(in: &cancellables)
        
        // Handle budget deletion
        input.deleteBudget
            .sink { [weak self] budgetId in
                self?.deleteBudget(budgetId: budgetId)
            }
            .store(in: &cancellables)
        
        // Return combined output publishers
        return Output(
            budgets: budgets.eraseToAnyPublisher(),
            isLoading: isLoading.eraseToAnyPublisher(),
            error: error.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    
    /// Loads budgets with optional period filter
    /// - Parameter period: Optional period string for filtering
    private func loadBudgets(period: String?) {
        isLoading.send(true)
        error.send(nil)
        
        let periodEnum = period.flatMap { BudgetPeriod(rawValue: $0) }
        
        budgetUseCase.getAllBudgets(period: periodEnum)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading.send(false)
                    if case .failure(let error) = completion {
                        self?.error.send(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] budgets in
                    self?.budgets.send(budgets)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Deletes a budget by ID
    /// - Parameter budgetId: UUID of budget to delete
    private func deleteBudget(budgetId: UUID) {
        budgetUseCase.deleteBudget(budgetId: budgetId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error.send(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] _ in
                    // Remove deleted budget from current list
                    var currentBudgets = self?.budgets.value ?? []
                    currentBudgets.removeAll { $0.id == budgetId }
                    self?.budgets.send(currentBudgets)
                }
            )
            .store(in: &cancellables)
    }
}