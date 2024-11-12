//
// GoalListViewModelTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Verify XCTest framework is properly linked in test target
// 2. Ensure test coverage reporting is configured
// 3. Review test data values match business requirements
// 4. Validate error scenarios cover all edge cases

// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

// Implements requirement: Client Applications Architecture (2.2.1 Client Applications)
final class GoalListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: GoalListViewModel!
    private var mockUseCase: MockGoalUseCase!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockGoalUseCase()
        sut = GoalListViewModel(useCase: mockUseCase)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    // Implements requirement: Client Applications Architecture (2.2.1 Client Applications)
    func testInitialization() {
        // Given
        let expectation = XCTestExpectation(description: "Initial state verification")
        var receivedGoals: [Goal]?
        var receivedIsLoading: Bool?
        var receivedError: Error??
        
        // When
        let output = sut.transform(.loadTrigger)
        
        output.goals
            .sink { goals in
                receivedGoals = goals
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        output.isLoading
            .sink { isLoading in
                receivedIsLoading = isLoading
            }
            .store(in: &cancellables)
        
        output.error
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(sut)
        XCTAssertEqual(receivedGoals?.count, 0)
        XCTAssertEqual(receivedIsLoading, false)
        XCTAssertNil(receivedError)
    }
    
    // Implements requirements:
    // - Goal Management (1.2 Scope/Goal Management)
    // - Cross-platform Data Synchronization (1.1 System Overview/Client Applications)
    func testFetchGoalsSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Fetch goals success")
        let mockGoals = [
            try Goal(name: "Test Goal 1", type: .savings, targetAmount: 1000, targetDate: Date().addingTimeInterval(86400)),
            try Goal(name: "Test Goal 2", type: .investment, targetAmount: 5000, targetDate: Date().addingTimeInterval(86400 * 2))
        ]
        mockUseCase.fetchGoalsResult = .success(mockGoals)
        
        var receivedGoals: [Goal]?
        var loadingStates: [Bool] = []
        var receivedError: Error??
        
        let output = sut.transform(.loadTrigger)
        
        // When
        output.goals
            .sink { goals in
                receivedGoals = goals
                expectation.fulfill()
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
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedGoals?.count, 2)
        XCTAssertEqual(receivedGoals?[0].name, "Test Goal 1")
        XCTAssertEqual(receivedGoals?[1].name, "Test Goal 2")
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertNil(receivedError)
    }
    
    // Implements requirement: Client Applications Architecture (2.2.1 Client Applications)
    func testFetchGoalsFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch goals failure")
        let mockError = NSError(domain: "TestError", code: -1, userInfo: nil)
        mockUseCase.fetchGoalsResult = .failure(mockError)
        
        var receivedGoals: [Goal]?
        var loadingStates: [Bool] = []
        var receivedError: Error??
        
        let output = sut.transform(.loadTrigger)
        
        // When
        output.goals
            .sink { goals in
                receivedGoals = goals
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
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedGoals?.count, 0)
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertNotNil(receivedError)
        XCTAssertEqual((receivedError as NSError?)?.domain, "TestError")
    }
    
    // Implements requirement: Goal Management (1.2 Scope/Goal Management)
    func testGoalSelection() throws {
        // Given
        let expectation = XCTestExpectation(description: "Goal selection")
        let mockGoal = try Goal(name: "Selected Goal", type: .savings, targetAmount: 1000, targetDate: Date().addingTimeInterval(86400))
        var receivedSelectedGoal: Goal?
        
        let output = sut.transform(.selectGoal(mockGoal))
        
        // When
        output.selectedGoal
            .sink { goal in
                receivedSelectedGoal = goal
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedSelectedGoal?.id, mockGoal.id)
        XCTAssertEqual(receivedSelectedGoal?.name, "Selected Goal")
    }
    
    // Implements requirements:
    // - Goal Management (1.2 Scope/Goal Management)
    // - Cross-platform Data Synchronization (1.1 System Overview/Client Applications)
    func testGoalDeletionSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Goal deletion success")
        let mockGoal = try Goal(name: "Goal to Delete", type: .savings, targetAmount: 1000, targetDate: Date().addingTimeInterval(86400))
        mockUseCase.deleteGoalResult = .success(())
        
        var loadingStates: [Bool] = []
        var receivedError: Error??
        
        let output = sut.transform(.deleteGoal(mockGoal.id))
        
        // When
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.error
            .sink { error in
                receivedError = error
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertNil(receivedError)
    }
    
    // Implements requirement: Client Applications Architecture (2.2.1 Client Applications)
    func testGoalDeletionFailure() throws {
        // Given
        let expectation = XCTestExpectation(description: "Goal deletion failure")
        let mockGoal = try Goal(name: "Goal to Delete", type: .savings, targetAmount: 1000, targetDate: Date().addingTimeInterval(86400))
        let mockError = NSError(domain: "DeleteError", code: -1, userInfo: nil)
        mockUseCase.deleteGoalResult = .failure(mockError)
        
        var loadingStates: [Bool] = []
        var receivedError: Error??
        
        let output = sut.transform(.deleteGoal(mockGoal.id))
        
        // When
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.error
            .sink { error in
                receivedError = error
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertNotNil(receivedError)
        XCTAssertEqual((receivedError as NSError?)?.domain, "DeleteError")
    }
}

// MARK: - Mock Goal Use Case

final class MockGoalUseCase: GoalUseCaseProtocol {
    var fetchGoalsResult: Result<[Goal], Error> = .success([])
    var deleteGoalResult: Result<Void, Error> = .success(())
    
    func fetchGoals() -> AnyPublisher<[Goal], Error> {
        return fetchGoalsResult.publisher
            .eraseToAnyPublisher()
    }
    
    func deleteGoal(goalId: UUID) -> AnyPublisher<Void, Error> {
        return deleteGoalResult.publisher
            .eraseToAnyPublisher()
    }
}