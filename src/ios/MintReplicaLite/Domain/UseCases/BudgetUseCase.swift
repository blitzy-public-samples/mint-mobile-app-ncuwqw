// HUMAN TASKS:
// 1. Verify error handling strategy aligns with team guidelines
// 2. Review alert threshold configurations with product team
// 3. Confirm budget period calculations for fiscal year alignment

// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Internal imports with relative paths
import "../Models/Budget"
import "../../Data/Repositories/BudgetRepository"

/// BudgetUseCase implements business logic for budget management operations with thread-safe reactive data flow
/// Requirements addressed:
/// - Category-based budgeting (1.2 Scope/Budget Management)
/// - Progress monitoring (1.2 Scope/Budget Management)
/// - Customizable alerts (1.2 Scope/Budget Management)
/// - Budget vs. actual reporting (1.2 Scope/Budget Management)
@objc final class BudgetUseCase {
    
    // MARK: - Properties
    
    private let repository: BudgetRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes use case with required dependencies
    /// - Parameter repository: Repository instance for data operations
    init(repository: BudgetRepository) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    /// Creates a new budget for a category with validation
    /// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
    /// - Parameters:
    ///   - categoryId: Category identifier
    ///   - amount: Budget amount
    ///   - period: Budget period type
    ///   - alertThreshold: Alert threshold percentage (0.0 to 1.0)
    /// - Returns: Publisher with created budget or error
    func createBudget(categoryId: UUID, 
                     amount: Decimal, 
                     period: BudgetPeriod, 
                     alertThreshold: Double) -> AnyPublisher<Budget, Error> {
        // Validate input parameters
        guard amount > 0 else {
            return Fail(error: NSError(domain: "BudgetUseCase",
                                     code: 4001,
                                     userInfo: [NSLocalizedDescriptionKey: "Budget amount must be greater than zero"]))
                .eraseToAnyPublisher()
        }
        
        guard alertThreshold > 0 && alertThreshold <= 1.0 else {
            return Fail(error: NSError(domain: "BudgetUseCase",
                                     code: 4002,
                                     userInfo: [NSLocalizedDescriptionKey: "Alert threshold must be between 0 and 1"]))
                .eraseToAnyPublisher()
        }
        
        // Calculate period dates
        let startDate = Date()
        let endDate: Date
        
        switch period {
        case .monthly:
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
        case .quarterly:
            endDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate)!
        case .annual:
            endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
        }
        
        do {
            // Create new budget instance
            let budget = try Budget(id: UUID(),
                                  categoryId: categoryId,
                                  amount: amount,
                                  period: period,
                                  alertThreshold: alertThreshold,
                                  alertEnabled: true,
                                  startDate: startDate,
                                  endDate: endDate)
            
            // Save using repository
            return repository.saveBudget(budget)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    /// Updates budget amount and recalculates progress
    /// Requirement: Budget vs. actual reporting (1.2 Scope/Budget Management)
    /// - Parameters:
    ///   - budgetId: Budget identifier
    ///   - newAmount: Updated budget amount
    /// - Returns: Publisher with updated budget or error
    func updateBudgetAmount(budgetId: UUID, 
                          newAmount: Decimal) -> AnyPublisher<Budget, Error> {
        guard newAmount > 0 else {
            return Fail(error: NSError(domain: "BudgetUseCase",
                                     code: 4003,
                                     userInfo: [NSLocalizedDescriptionKey: "Budget amount must be greater than zero"]))
                .eraseToAnyPublisher()
        }
        
        return repository.getBudget(id: budgetId)
            .flatMap { budget -> AnyPublisher<Budget, Error> in
                guard let budget = budget else {
                    return Fail(error: NSError(domain: "BudgetUseCase",
                                             code: 4004,
                                             userInfo: [NSLocalizedDescriptionKey: "Budget not found"]))
                        .eraseToAnyPublisher()
                }
                
                do {
                    // Create updated budget with new amount
                    let updatedBudget = try Budget(id: budget.id,
                                                 categoryId: budget.categoryId,
                                                 amount: newAmount,
                                                 period: budget.period,
                                                 alertThreshold: budget.alertThreshold,
                                                 alertEnabled: budget.alertEnabled,
                                                 startDate: budget.startDate,
                                                 endDate: budget.endDate)
                    try updatedBudget.updateSpent(budget.spent)
                    
                    return repository.saveBudget(updatedBudget)
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Updates spent amount and checks alert conditions
    /// Requirements addressed:
    /// - Progress monitoring (1.2 Scope/Budget Management)
    /// - Customizable alerts (1.2 Scope/Budget Management)
    /// - Parameters:
    ///   - budgetId: Budget identifier
    ///   - amount: Spent amount
    /// - Returns: Publisher with updated budget and alert status
    func trackSpending(budgetId: UUID, 
                      amount: Decimal) -> AnyPublisher<(Budget, Bool), Error> {
        return repository.getBudget(id: budgetId)
            .flatMap { budget -> AnyPublisher<(Budget, Bool), Error> in
                guard let budget = budget else {
                    return Fail(error: NSError(domain: "BudgetUseCase",
                                             code: 4005,
                                             userInfo: [NSLocalizedDescriptionKey: "Budget not found"]))
                        .eraseToAnyPublisher()
                }
                
                do {
                    try budget.updateSpent(amount)
                    let shouldAlert = budget.shouldAlert()
                    
                    return repository.saveBudget(budget)
                        .map { ($0, shouldAlert) }
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Retrieves budget progress and remaining amount
    /// Requirement: Budget vs. actual reporting (1.2 Scope/Budget Management)
    /// - Parameter budgetId: Budget identifier
    /// - Returns: Publisher with progress percentage and remaining amount
    func getBudgetProgress(budgetId: UUID) -> AnyPublisher<(Double, Decimal), Error> {
        return repository.getBudget(id: budgetId)
            .map { budget -> (Double, Decimal) in
                guard let budget = budget else {
                    throw NSError(domain: "BudgetUseCase",
                                code: 4006,
                                userInfo: [NSLocalizedDescriptionKey: "Budget not found"])
                }
                
                let progress = budget.getProgress()
                let remaining = budget.amount - budget.spent
                
                return (progress, remaining)
            }
            .eraseToAnyPublisher()
    }
    
    /// Retrieves all budgets with optional period filter
    /// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
    /// - Parameter period: Optional budget period filter
    /// - Returns: Publisher with array of budgets
    func getAllBudgets(period: BudgetPeriod? = nil) -> AnyPublisher<[Budget], Error> {
        return repository.getAllBudgets()
            .map { budgets in
                guard let period = period else { return budgets }
                return budgets.filter { $0.period == period }
            }
            .eraseToAnyPublisher()
    }
    
    /// Deletes an existing budget
    /// - Parameter budgetId: Budget identifier
    /// - Returns: Publisher with success or error
    func deleteBudget(budgetId: UUID) -> AnyPublisher<Void, Error> {
        return repository.getBudget(id: budgetId)
            .flatMap { budget -> AnyPublisher<Void, Error> in
                guard budget != nil else {
                    return Fail(error: NSError(domain: "BudgetUseCase",
                                             code: 4007,
                                             userInfo: [NSLocalizedDescriptionKey: "Budget not found"]))
                        .eraseToAnyPublisher()
                }
                
                return self.repository.deleteBudget(id: budgetId)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}