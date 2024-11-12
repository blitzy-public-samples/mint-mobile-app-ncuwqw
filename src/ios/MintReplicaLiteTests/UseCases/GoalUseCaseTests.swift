//
// GoalUseCaseTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Verify test coverage meets minimum requirements (>80%)
// 2. Review test data values match business requirements
// 3. Ensure error scenarios cover all edge cases
// 4. Add performance tests if needed for large goal datasets

// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

// Implements requirement: Goal Management (1.2 Scope/Goal Management)
final class MockGoalRepository: GoalRepositoryProtocol {
    var storedGoals: [Goal] = []
    var mockError: Error?
    
    func createGoal(_ goal: Goal) -> Result<Goal, Error> {
        if let error = mockError {
            return .failure(error)
        }
        storedGoals.append(goal)
        return .success(goal)
    }
    
    func fetchGoal(id: UUID) -> Result<Goal?, Error> {
        if let error = mockError {
            return .failure(error)
        }
        return .success(storedGoals.first { $0.id == id })
    }
    
    func fetchAllGoals() -> Result<[Goal], Error> {
        if let error = mockError {
            return .failure(error)
        }
        return .success(storedGoals)
    }
    
    func updateGoal(_ goal: Goal) -> Result<Goal, Error> {
        if let error = mockError {
            return .failure(error)
        }
        if let index = storedGoals.firstIndex(where: { $0.id == goal.id }) {
            storedGoals[index] = goal
            return .success(goal)
        }
        return .failure(NSError(domain: "MockRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Goal not found"]))
    }
    
    func deleteGoal(id: UUID) -> Result<Void, Error> {
        if let error = mockError {
            return .failure(error)
        }
        storedGoals.removeAll { $0.id == id }
        return .success(())
    }
}

// Implements requirements:
// - Goal Management (1.2 Scope/Goal Management)
// - Cross-platform Data Synchronization (1.1 System Overview/Client Applications)
final class GoalUseCaseTests: XCTestCase {
    private var sut: GoalUseCase!
    private var mockRepository: MockGoalRepository!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockGoalRepository()
        sut = GoalUseCase(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        mockRepository.storedGoals = []
        sut = nil
        super.tearDown()
    }
    
    func testCreateGoal_Success() {
        // Given
        let expectation = XCTestExpectation(description: "Create goal")
        let name = "Emergency Fund"
        let type = GoalType.emergency
        let targetAmount = Decimal(10000)
        let targetDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        // When
        sut.createGoal(name: name, type: type, targetAmount: targetAmount, targetDate: targetDate)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                },
                receiveValue: { goal in
                    // Then
                    XCTAssertEqual(goal.name, name)
                    XCTAssertEqual(goal.type, type)
                    XCTAssertEqual(goal.targetAmount, targetAmount)
                    XCTAssertEqual(goal.targetDate, targetDate)
                    XCTAssertEqual(goal.currentAmount, 0)
                    XCTAssertEqual(goal.status, .notStarted)
                    XCTAssertTrue(self.mockRepository.storedGoals.contains(where: { $0.id == goal.id }))
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testCreateGoal_InvalidName() {
        // Given
        let expectation = XCTestExpectation(description: "Create goal with invalid name")
        let name = ""
        let type = GoalType.savings
        let targetAmount = Decimal(5000)
        let targetDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        // When
        sut.createGoal(name: name, type: type, targetAmount: targetAmount, targetDate: targetDate)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected failure but got success")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testUpdateGoalProgress_Success() {
        // Given
        let expectation = XCTestExpectation(description: "Update goal progress")
        let goal = try! Goal(name: "Vacation Fund", type: .savings, targetAmount: 5000, targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!)
        _ = mockRepository.createGoal(goal)
        let newAmount = Decimal(2500)
        
        // When
        sut.updateGoalProgress(goalId: goal.id, amount: newAmount)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                },
                receiveValue: { updatedGoal in
                    // Then
                    XCTAssertEqual(updatedGoal.currentAmount, newAmount)
                    XCTAssertEqual(updatedGoal.progress, 50)
                    XCTAssertEqual(updatedGoal.status, .inProgress)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testLinkAccountToGoal_Success() {
        // Given
        let expectation = XCTestExpectation(description: "Link account to goal")
        let goal = try! Goal(name: "House Down Payment", type: .savings, targetAmount: 50000, targetDate: Calendar.current.date(byAdding: .years, value: 2, to: Date())!)
        _ = mockRepository.createGoal(goal)
        let accountId = UUID()
        
        // When
        sut.linkAccountToGoal(goalId: goal.id, accountId: accountId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                },
                receiveValue: { updatedGoal in
                    // Then
                    XCTAssertTrue(updatedGoal.linkedAccountIds.contains(accountId))
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testFetchGoals_Success() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch all goals")
        let goal1 = try! Goal(name: "Goal 1", type: .savings, targetAmount: 1000, targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!)
        let goal2 = try! Goal(name: "Goal 2", type: .investment, targetAmount: 2000, targetDate: Calendar.current.date(byAdding: .year, value: 2, to: Date())!)
        _ = mockRepository.createGoal(goal1)
        _ = mockRepository.createGoal(goal2)
        
        // When
        sut.fetchGoals()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                },
                receiveValue: { goals in
                    // Then
                    XCTAssertEqual(goals.count, 2)
                    XCTAssertTrue(goals.contains(where: { $0.id == goal1.id }))
                    XCTAssertTrue(goals.contains(where: { $0.id == goal2.id }))
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDeleteGoal_Success() {
        // Given
        let expectation = XCTestExpectation(description: "Delete goal")
        let goal = try! Goal(name: "Test Goal", type: .custom, targetAmount: 3000, targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!)
        _ = mockRepository.createGoal(goal)
        
        // When
        sut.deleteGoal(goalId: goal.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                    
                    // Then
                    XCTAssertFalse(self.mockRepository.storedGoals.contains(where: { $0.id == goal.id }))
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
}