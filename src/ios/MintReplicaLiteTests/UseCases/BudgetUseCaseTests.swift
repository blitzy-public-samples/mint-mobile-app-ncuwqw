// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

/// Unit test suite for BudgetUseCase verifying budget management functionality
/// Requirements addressed:
/// - Category-based budgeting (1.2 Scope/Budget Management)
/// - Progress monitoring (1.2 Scope/Budget Management)
/// - Customizable alerts (1.2 Scope/Budget Management)
final class BudgetUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: BudgetUseCase!
    private var mockRepository: MockBudgetRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        mockRepository = MockBudgetRepository()
        sut = BudgetUseCase(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests successful budget creation with valid parameters
    /// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
    func testCreateBudget_Success() {
        // Given
        let categoryId = UUID()
        let amount: Decimal = 1000.0
        let period: BudgetPeriod = .monthly
        let alertThreshold = 0.8
        
        var savedBudget: Budget?
        let expectation = expectation(description: "Create budget")
        
        // When
        sut.createBudget(categoryId: categoryId, 
                        amount: amount, 
                        period: period, 
                        alertThreshold: alertThreshold)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail")
                    }
                },
                receiveValue: { budget in
                    savedBudget = budget
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertNotNil(savedBudget)
        XCTAssertEqual(savedBudget?.categoryId, categoryId)
        XCTAssertEqual(savedBudget?.amount, amount)
        XCTAssertEqual(savedBudget?.period, period)
        XCTAssertEqual(savedBudget?.alertThreshold, alertThreshold)
    }
    
    /// Tests successful budget amount update
    /// Requirement: Progress monitoring (1.2 Scope/Budget Management)
    func testUpdateBudgetAmount_Success() {
        // Given
        let budgetId = UUID()
        let initialAmount: Decimal = 1000.0
        let newAmount: Decimal = 1500.0
        
        let budget = try! Budget(id: budgetId,
                               categoryId: UUID(),
                               amount: initialAmount,
                               period: .monthly,
                               alertThreshold: 0.8,
                               alertEnabled: true,
                               startDate: Date(),
                               endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!)
        
        mockRepository.budgets[budgetId] = budget
        
        var updatedBudget: Budget?
        let expectation = expectation(description: "Update budget amount")
        
        // When
        sut.updateBudgetAmount(budgetId: budgetId, newAmount: newAmount)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail")
                    }
                },
                receiveValue: { budget in
                    updatedBudget = budget
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertNotNil(updatedBudget)
        XCTAssertEqual(updatedBudget?.amount, newAmount)
    }
    
    /// Tests spending tracking with alert threshold
    /// Requirements addressed:
    /// - Progress monitoring (1.2 Scope/Budget Management)
    /// - Customizable alerts (1.2 Scope/Budget Management)
    func testTrackSpending_AlertTriggered() {
        // Given
        let budgetId = UUID()
        let amount: Decimal = 1000.0
        let alertThreshold = 0.8
        let spentAmount: Decimal = 850.0 // 85% spent, should trigger alert
        
        let budget = try! Budget(id: budgetId,
                               categoryId: UUID(),
                               amount: amount,
                               period: .monthly,
                               alertThreshold: alertThreshold,
                               alertEnabled: true,
                               startDate: Date(),
                               endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!)
        
        mockRepository.budgets[budgetId] = budget
        
        var resultBudget: Budget?
        var alertTriggered = false
        let expectation = expectation(description: "Track spending")
        
        // When
        sut.trackSpending(budgetId: budgetId, amount: spentAmount)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail")
                    }
                },
                receiveValue: { (budget, shouldAlert) in
                    resultBudget = budget
                    alertTriggered = shouldAlert
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertNotNil(resultBudget)
        XCTAssertEqual(resultBudget?.spent, spentAmount)
        XCTAssertTrue(alertTriggered)
    }
    
    /// Tests budget progress calculation
    /// Requirement: Progress monitoring (1.2 Scope/Budget Management)
    func testGetBudgetProgress_Success() {
        // Given
        let budgetId = UUID()
        let amount: Decimal = 1000.0
        let spent: Decimal = 250.0 // 25% spent
        
        let budget = try! Budget(id: budgetId,
                               categoryId: UUID(),
                               amount: amount,
                               period: .monthly,
                               alertThreshold: 0.8,
                               alertEnabled: true,
                               startDate: Date(),
                               endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!)
        try! budget.updateSpent(spent)
        
        mockRepository.budgets[budgetId] = budget
        
        var progress: Double?
        var remaining: Decimal?
        let expectation = expectation(description: "Get budget progress")
        
        // When
        sut.getBudgetProgress(budgetId: budgetId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail")
                    }
                },
                receiveValue: { (progressValue, remainingAmount) in
                    progress = progressValue
                    remaining = remainingAmount
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(progress, 0.25, accuracy: 0.01)
        XCTAssertEqual(remaining, 750.0)
    }
    
    /// Tests successful budget deletion
    /// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
    func testDeleteBudget_Success() {
        // Given
        let budgetId = UUID()
        let budget = try! Budget(id: budgetId,
                               categoryId: UUID(),
                               amount: 1000.0,
                               period: .monthly,
                               alertThreshold: 0.8,
                               alertEnabled: true,
                               startDate: Date(),
                               endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!)
        
        mockRepository.budgets[budgetId] = budget
        
        let expectation = expectation(description: "Delete budget")
        
        // When
        sut.deleteBudget(budgetId: budgetId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertNil(mockRepository.budgets[budgetId])
    }
}

// MARK: - Mock Repository

/// Mock implementation of BudgetRepository for testing
private final class MockBudgetRepository: BudgetRepository {
    var budgets: [UUID: Budget] = [:]
    var mockError: Error?
    
    override func getBudget(id: UUID) -> AnyPublisher<Budget?, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(budgets[id])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    override func getAllBudgets(predicate: NSPredicate? = nil) -> AnyPublisher<[Budget], Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(Array(budgets.values))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    override func saveBudget(_ budget: Budget) -> AnyPublisher<Budget, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        budgets[budget.id] = budget
        return Just(budget)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    override func deleteBudget(id: UUID) -> AnyPublisher<Void, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        budgets.removeValue(forKey: id)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}