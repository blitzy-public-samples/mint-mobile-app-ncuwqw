//
// GoalRepositoryTests.swift
// MintReplicaLiteTests
//

// HUMAN TASKS:
// 1. Verify test database configuration matches production schema
// 2. Review test coverage metrics and add additional test cases if needed
// 3. Set up CI pipeline for automated test execution
// 4. Configure test data cleanup for integration tests

// XCTest framework - iOS 14.0+
import XCTest
// CoreData framework - iOS 14.0+
import CoreData
@testable import MintReplicaLite

// Implements requirements:
// - Goal Management (1.2 Scope/Goal Management)
// - Local Data Persistence (4.3.2 Client Storage/iOS)
final class GoalRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: GoalRepository!
    private var coreDataManager: CoreDataManager!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager.shared
        sut = GoalRepository(coreDataManager: coreDataManager)
        _ = coreDataManager.clearDatabase()
    }
    
    override func tearDown() {
        _ = coreDataManager.clearDatabase()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testCreateGoal() throws {
        // Given
        let name = "Emergency Fund"
        let type = GoalType.emergency
        let targetAmount = Decimal(10000)
        let targetDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let goal = try Goal(name: name, type: type, targetAmount: targetAmount, targetDate: targetDate)
        
        // When
        let result = sut.createGoal(goal)
        
        // Then
        switch result {
        case .success(let createdGoal):
            XCTAssertNotNil(createdGoal.id)
            XCTAssertEqual(createdGoal.name, name)
            XCTAssertEqual(createdGoal.type, type)
            XCTAssertEqual(createdGoal.targetAmount, targetAmount)
            XCTAssertEqual(createdGoal.targetDate.timeIntervalSinceReferenceDate,
                          targetDate.timeIntervalSinceReferenceDate,
                          accuracy: 1.0)
            XCTAssertEqual(createdGoal.currentAmount, 0)
            XCTAssertTrue(createdGoal.isActive)
            
            // Verify persistence
            let fetchResult = sut.fetchGoal(id: createdGoal.id)
            guard case .success(let fetchedGoal) = fetchResult,
                  let goal = fetchedGoal else {
                XCTFail("Failed to fetch created goal")
                return
            }
            XCTAssertEqual(goal.id, createdGoal.id)
            
        case .failure(let error):
            XCTFail("Goal creation failed with error: \(error.localizedDescription)")
        }
    }
    
    func testFetchGoal() throws {
        // Given
        let goal = try Goal(
            name: "Vacation Fund",
            type: .savings,
            targetAmount: 5000,
            targetDate: Date().addingTimeInterval(86400 * 365)
        )
        let createResult = sut.createGoal(goal)
        guard case .success(let createdGoal) = createResult else {
            XCTFail("Failed to create test goal")
            return
        }
        
        // When
        let result = sut.fetchGoal(id: createdGoal.id)
        
        // Then
        switch result {
        case .success(let fetchedGoal):
            XCTAssertNotNil(fetchedGoal)
            XCTAssertEqual(fetchedGoal?.id, createdGoal.id)
            XCTAssertEqual(fetchedGoal?.name, goal.name)
            XCTAssertEqual(fetchedGoal?.type, goal.type)
            XCTAssertEqual(fetchedGoal?.targetAmount, goal.targetAmount)
            
        case .failure(let error):
            XCTFail("Goal fetch failed with error: \(error.localizedDescription)")
        }
    }
    
    func testFetchAllGoals() throws {
        // Given
        let goals = try [
            Goal(name: "House Down Payment", type: .savings, targetAmount: 50000, targetDate: Date().addingTimeInterval(86400 * 730)),
            Goal(name: "Car Loan", type: .debt, targetAmount: 25000, targetDate: Date().addingTimeInterval(86400 * 365)),
            Goal(name: "Investment Portfolio", type: .investment, targetAmount: 100000, targetDate: Date().addingTimeInterval(86400 * 1095))
        ]
        
        for goal in goals {
            guard case .success = sut.createGoal(goal) else {
                XCTFail("Failed to create test goal")
                return
            }
        }
        
        // When
        let result = sut.fetchAllGoals()
        
        // Then
        switch result {
        case .success(let fetchedGoals):
            XCTAssertEqual(fetchedGoals.count, goals.count)
            
            // Verify sorting by target date
            let sortedDates = fetchedGoals.map { $0.targetDate }
            XCTAssertEqual(sortedDates, sortedDates.sorted())
            
        case .failure(let error):
            XCTFail("Fetch all goals failed with error: \(error.localizedDescription)")
        }
    }
    
    func testUpdateGoal() throws {
        // Given
        let goal = try Goal(
            name: "Retirement Fund",
            type: .retirement,
            targetAmount: 1000000,
            targetDate: Date().addingTimeInterval(86400 * 3650)
        )
        
        guard case .success(let createdGoal) = sut.createGoal(goal) else {
            XCTFail("Failed to create test goal")
            return
        }
        
        // When
        let updatedName = "Early Retirement Fund"
        let updatedAmount = Decimal(1500000)
        createdGoal.name = updatedName
        try createdGoal.updateProgress(amount: 50000)
        
        let result = sut.updateGoal(createdGoal)
        
        // Then
        switch result {
        case .success(let updatedGoal):
            XCTAssertEqual(updatedGoal.id, createdGoal.id)
            XCTAssertEqual(updatedGoal.name, updatedName)
            XCTAssertEqual(updatedGoal.currentAmount, 50000)
            
            // Verify persistence
            let fetchResult = sut.fetchGoal(id: updatedGoal.id)
            guard case .success(let fetchedGoal) = fetchResult,
                  let goal = fetchedGoal else {
                XCTFail("Failed to fetch updated goal")
                return
            }
            XCTAssertEqual(goal.name, updatedName)
            XCTAssertEqual(goal.currentAmount, 50000)
            
        case .failure(let error):
            XCTFail("Goal update failed with error: \(error.localizedDescription)")
        }
    }
    
    func testDeleteGoal() throws {
        // Given
        let goal = try Goal(
            name: "Emergency Fund",
            type: .emergency,
            targetAmount: 15000,
            targetDate: Date().addingTimeInterval(86400 * 180)
        )
        
        guard case .success(let createdGoal) = sut.createGoal(goal) else {
            XCTFail("Failed to create test goal")
            return
        }
        
        // When
        let result = sut.deleteGoal(id: createdGoal.id)
        
        // Then
        switch result {
        case .success:
            // Verify deletion
            let fetchResult = sut.fetchGoal(id: createdGoal.id)
            guard case .success(let fetchedGoal) = fetchResult else {
                XCTFail("Fetch after deletion failed")
                return
            }
            XCTAssertNil(fetchedGoal, "Goal should be nil after deletion")
            
        case .failure(let error):
            XCTFail("Goal deletion failed with error: \(error.localizedDescription)")
        }
    }
}