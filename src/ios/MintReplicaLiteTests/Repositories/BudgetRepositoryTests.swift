// HUMAN TASKS:
// 1. Configure test scheme to use in-memory Core Data store
// 2. Add test target to project's test coverage requirements
// 3. Review and align test data with actual production data patterns
// 4. Ensure test database cleanup is properly configured in scheme

// XCTest framework - iOS 14.0+
import XCTest
// CoreData framework - iOS 14.0+
import CoreData
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

/// Test suite for BudgetRepository implementation
/// Requirements addressed:
/// - Category-based budgeting (1.2 Scope/Budget Management)
/// - Progress monitoring (1.2 Scope/Budget Management)
/// - Local Data Persistence (4.3.2 Client Storage/iOS)
final class BudgetRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: BudgetRepository!
    private var cancellables: Set<AnyCancellable>!
    private var testContainer: NSPersistentContainer!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        
        // Initialize in-memory Core Data test container
        testContainer = NSPersistentContainer(name: "MintReplicaLite")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        testContainer.persistentStoreDescriptions = [description]
        
        // Load persistent stores
        testContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        // Initialize test dependencies
        sut = BudgetRepository()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        // Cancel all publishers
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        
        // Remove test store
        guard let storeURL = testContainer.persistentStoreDescriptions.first?.url else {
            return
        }
        
        do {
            try testContainer.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSInMemoryStoreType, options: nil)
        } catch {
            print("Error removing test store: \(error)")
        }
        
        testContainer = nil
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests saving a new budget and verifying persistence
    /// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
    func testSaveBudget() {
        // Given
        let expectation = XCTestExpectation(description: "Save budget")
        let budgetId = UUID()
        let categoryId = UUID()
        let amount: Decimal = 1000.00
        let period = BudgetPeriod.monthly
        
        let testBudget = try! Budget(
            id: budgetId,
            categoryId: categoryId,
            amount: amount,
            period: period,
            alertThreshold: 0.75,
            alertEnabled: true,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        )
        
        // When
        sut.saveBudget(testBudget)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Failed to save budget: \(error)")
                    }
                },
                receiveValue: { savedBudget in
                    // Then
                    XCTAssertEqual(savedBudget.id, budgetId)
                    XCTAssertEqual(savedBudget.categoryId, categoryId)
                    XCTAssertEqual(savedBudget.amount, amount)
                    XCTAssertEqual(savedBudget.period, period)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Tests retrieving a specific budget by ID
    /// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
    func testGetBudget() {
        // Given
        let expectation = XCTestExpectation(description: "Get budget")
        let budgetId = UUID()
        let testBudget = try! Budget(
            id: budgetId,
            categoryId: UUID(),
            amount: 1000.00,
            period: .monthly,
            alertThreshold: 0.75,
            alertEnabled: true,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        )
        
        // Save test budget first
        sut.saveBudget(testBudget)
            .flatMap { _ in
                // When
                self.sut.getBudget(id: budgetId)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Failed to get budget: \(error)")
                    }
                },
                receiveValue: { retrievedBudget in
                    // Then
                    XCTAssertNotNil(retrievedBudget)
                    XCTAssertEqual(retrievedBudget?.id, budgetId)
                    XCTAssertEqual(retrievedBudget?.amount, testBudget.amount)
                    XCTAssertEqual(retrievedBudget?.period, testBudget.period)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Tests retrieving all budgets from storage
    /// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
    func testGetAllBudgets() {
        // Given
        let expectation = XCTestExpectation(description: "Get all budgets")
        let testBudgets = [
            try! Budget(
                id: UUID(),
                categoryId: UUID(),
                amount: 1000.00,
                period: .monthly,
                alertThreshold: 0.75,
                alertEnabled: true,
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
            ),
            try! Budget(
                id: UUID(),
                categoryId: UUID(),
                amount: 2000.00,
                period: .quarterly,
                alertThreshold: 0.80,
                alertEnabled: true,
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!
            )
        ]
        
        // Save test budgets first
        Publishers.MergeMany(testBudgets.map { sut.saveBudget($0) })
            .collect()
            .flatMap { _ in
                // When
                self.sut.getAllBudgets()
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Failed to get all budgets: \(error)")
                    }
                },
                receiveValue: { budgets in
                    // Then
                    XCTAssertEqual(budgets.count, testBudgets.count)
                    XCTAssertEqual(Set(budgets.map { $0.id }), Set(testBudgets.map { $0.id }))
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Tests deleting a budget from storage
    /// Requirement: Local Data Persistence (4.3.2 Client Storage/iOS)
    func testDeleteBudget() {
        // Given
        let expectation = XCTestExpectation(description: "Delete budget")
        let budgetId = UUID()
        let testBudget = try! Budget(
            id: budgetId,
            categoryId: UUID(),
            amount: 1000.00,
            period: .monthly,
            alertThreshold: 0.75,
            alertEnabled: true,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        )
        
        // Save test budget first
        sut.saveBudget(testBudget)
            .flatMap { _ in
                // When
                self.sut.deleteBudget(id: budgetId)
            }
            .flatMap { _ in
                // Verify deletion
                self.sut.getBudget(id: budgetId)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Failed to delete budget: \(error)")
                    }
                },
                receiveValue: { budget in
                    // Then
                    XCTAssertNil(budget)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Tests budget synchronization with remote source
    /// Requirement: Progress monitoring (1.2 Scope/Budget Management)
    func testSyncBudgets() {
        // Given
        let expectation = XCTestExpectation(description: "Sync budgets")
        let localBudget = try! Budget(
            id: UUID(),
            categoryId: UUID(),
            amount: 1000.00,
            period: .monthly,
            alertThreshold: 0.75,
            alertEnabled: true,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        )
        
        // Save local budget first
        sut.saveBudget(localBudget)
            .flatMap { _ in
                // When
                self.sut.syncBudgets()
            }
            .flatMap { _ in
                // Verify sync
                self.sut.getAllBudgets()
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Failed to sync budgets: \(error)")
                    }
                },
                receiveValue: { budgets in
                    // Then
                    XCTAssertFalse(budgets.isEmpty)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}