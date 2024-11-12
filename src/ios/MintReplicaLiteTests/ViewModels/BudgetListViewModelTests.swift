// HUMAN TASKS:
// 1. Verify XCTest framework is properly linked in test target
// 2. Ensure test target minimum deployment target matches main target (iOS 14.0+)
// 3. Configure test scheme to enable code coverage reporting

// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

/// Test suite for BudgetListViewModel verifying presentation logic and user interactions
/// Requirements addressed:
/// - Category-based budgeting (1.2 Scope/Budget Management): Verifies budget list management
/// - Progress monitoring (1.2 Scope/Budget Management): Tests budget progress tracking
final class BudgetListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: BudgetListViewModel!
    private var mockBudgetUseCase: MockBudgetUseCase!
    private var cancellables: Set<AnyCancellable>!
    private var viewDidLoadTrigger: PassthroughSubject<Void, Never>!
    private var periodSelectedTrigger: PassthroughSubject<String?, Never>!
    private var deleteBudgetTrigger: PassthroughSubject<UUID, Never>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        mockBudgetUseCase = MockBudgetUseCase()
        sut = BudgetListViewModel(budgetUseCase: mockBudgetUseCase)
        cancellables = Set<AnyCancellable>()
        viewDidLoadTrigger = PassthroughSubject<Void, Never>()
        periodSelectedTrigger = PassthroughSubject<String?, Never>()
        deleteBudgetTrigger = PassthroughSubject<UUID, Never>()
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        sut = nil
        mockBudgetUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testLoadBudgetsSuccess() {
        // Given
        let testBudgets = [
            Budget(id: UUID(),
                  categoryId: UUID(),
                  amount: 1000,
                  period: .monthly,
                  alertThreshold: 0.8,
                  alertEnabled: true,
                  startDate: Date(),
                  endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!)!,
            Budget(id: UUID(),
                  categoryId: UUID(),
                  amount: 5000,
                  period: .monthly,
                  alertThreshold: 0.8,
                  alertEnabled: true,
                  startDate: Date(),
                  endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!)!
        ]
        
        mockBudgetUseCase.getAllBudgetsSubject.send(testBudgets)
        
        var receivedBudgets: [Budget] = []
        var loadingStates: [Bool] = []
        var receivedError: String?
        
        // When
        let input = BudgetListViewModel.Input(
            viewDidLoad: viewDidLoadTrigger.eraseToAnyPublisher(),
            periodSelected: periodSelectedTrigger.eraseToAnyPublisher(),
            deleteBudget: deleteBudgetTrigger.eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        output.budgets
            .sink { budgets in
                receivedBudgets = budgets
            }
            .store(in: &cancellables)
        
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.error
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)
        
        viewDidLoadTrigger.send(())
        mockBudgetUseCase.getAllBudgetsSubject.send(completion: .finished)
        
        // Then
        XCTAssertEqual(receivedBudgets.count, testBudgets.count)
        XCTAssertEqual(receivedBudgets[0].id, testBudgets[0].id)
        XCTAssertEqual(receivedBudgets[1].id, testBudgets[1].id)
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertNil(receivedError)
    }
    
    func testLoadBudgetsFailure() {
        // Given
        let expectedError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        var receivedBudgets: [Budget] = []
        var loadingStates: [Bool] = []
        var receivedError: String?
        
        // When
        let input = BudgetListViewModel.Input(
            viewDidLoad: viewDidLoadTrigger.eraseToAnyPublisher(),
            periodSelected: periodSelectedTrigger.eraseToAnyPublisher(),
            deleteBudget: deleteBudgetTrigger.eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        output.budgets
            .sink { budgets in
                receivedBudgets = budgets
            }
            .store(in: &cancellables)
        
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.error
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)
        
        viewDidLoadTrigger.send(())
        mockBudgetUseCase.getAllBudgetsSubject.send(completion: .failure(expectedError))
        
        // Then
        XCTAssertTrue(receivedBudgets.isEmpty)
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertEqual(receivedError, expectedError.localizedDescription)
    }
    
    func testDeleteBudgetSuccess() {
        // Given
        let budgetId = UUID()
        let testBudget = Budget(id: budgetId,
                              categoryId: UUID(),
                              amount: 1000,
                              period: .monthly,
                              alertThreshold: 0.8,
                              alertEnabled: true,
                              startDate: Date(),
                              endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!)!
        
        var receivedBudgets: [Budget] = []
        var receivedError: String?
        
        // When
        let input = BudgetListViewModel.Input(
            viewDidLoad: viewDidLoadTrigger.eraseToAnyPublisher(),
            periodSelected: periodSelectedTrigger.eraseToAnyPublisher(),
            deleteBudget: deleteBudgetTrigger.eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        output.budgets
            .sink { budgets in
                receivedBudgets = budgets
            }
            .store(in: &cancellables)
        
        output.error
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)
        
        mockBudgetUseCase.getAllBudgetsSubject.send([testBudget])
        viewDidLoadTrigger.send(())
        
        deleteBudgetTrigger.send(budgetId)
        mockBudgetUseCase.deleteBudgetSubject.send(())
        mockBudgetUseCase.deleteBudgetSubject.send(completion: .finished)
        
        // Then
        XCTAssertTrue(receivedBudgets.isEmpty)
        XCTAssertNil(receivedError)
    }
    
    func testPeriodFilteringSuccess() {
        // Given
        let monthlyBudget = Budget(id: UUID(),
                                 categoryId: UUID(),
                                 amount: 1000,
                                 period: .monthly,
                                 alertThreshold: 0.8,
                                 alertEnabled: true,
                                 startDate: Date(),
                                 endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!)!
        
        let annualBudget = Budget(id: UUID(),
                                categoryId: UUID(),
                                amount: 12000,
                                period: .annual,
                                alertThreshold: 0.8,
                                alertEnabled: true,
                                startDate: Date(),
                                endDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!)!
        
        var receivedBudgets: [Budget] = []
        var loadingStates: [Bool] = []
        var receivedError: String?
        
        // When
        let input = BudgetListViewModel.Input(
            viewDidLoad: viewDidLoadTrigger.eraseToAnyPublisher(),
            periodSelected: periodSelectedTrigger.eraseToAnyPublisher(),
            deleteBudget: deleteBudgetTrigger.eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        output.budgets
            .sink { budgets in
                receivedBudgets = budgets
            }
            .store(in: &cancellables)
        
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.error
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)
        
        mockBudgetUseCase.getAllBudgetsSubject.send([monthlyBudget, annualBudget])
        periodSelectedTrigger.send(BudgetPeriod.monthly.rawValue)
        
        // Then
        XCTAssertEqual(receivedBudgets.count, 1)
        XCTAssertEqual(receivedBudgets[0].id, monthlyBudget.id)
        XCTAssertEqual(receivedBudgets[0].period, .monthly)
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertNil(receivedError)
    }
}

// MARK: - Mock BudgetUseCase

final class MockBudgetUseCase: BudgetUseCase {
    let getAllBudgetsSubject = PassthroughSubject<[Budget], Error>()
    let deleteBudgetSubject = PassthroughSubject<Void, Error>()
    
    override func getAllBudgets(period: BudgetPeriod?) -> AnyPublisher<[Budget], Error> {
        return getAllBudgetsSubject.eraseToAnyPublisher()
    }
    
    override func deleteBudget(budgetId: UUID) -> AnyPublisher<Void, Error> {
        return deleteBudgetSubject.eraseToAnyPublisher()
    }
}