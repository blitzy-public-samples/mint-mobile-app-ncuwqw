// HUMAN TASKS:
// 1. Verify test environment has proper encryption keys configured
// 2. Ensure test database is properly isolated from production data
// 3. Configure test timeout values based on CI/CD pipeline requirements

// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

/// Test suite for TransactionRepository implementation verifying secure data handling and synchronization
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking)
/// - Cross-platform Data Synchronization (1.2 Scope/Account Management)
/// - Transaction Data Security (6.2.2 Sensitive Data Handling)
final class TransactionRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: TransactionRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        // Clear database to ensure test isolation
        // Requirement: Transaction Data Security (6.2.2 Sensitive Data Handling)
        CoreDataManager.shared.clearDatabase()
        
        sut = TransactionRepository()
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        
        // Clean up test data
        CoreDataManager.shared.clearDatabase()
        
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests retrieving transactions when database is empty
    /// Requirement: Financial Tracking (1.2 Scope/Financial Tracking)
    func testGetTransactions_WhenEmpty_ReturnsEmptyArray() {
        // Given
        let expectation = expectation(description: "Get transactions completes")
        var receivedTransactions: [Transaction]?
        var receivedError: Error?
        
        // When
        sut.getTransactions(startDate: nil, endDate: nil, accountId: nil, categoryId: nil)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { transactions in
                    receivedTransactions = transactions
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 5.0)
        XCTAssertNil(receivedError, "Should not receive any error")
        XCTAssertNotNil(receivedTransactions, "Should receive transactions array")
        XCTAssertEqual(receivedTransactions?.count, 0, "Should receive empty array")
    }
    
    /// Tests saving a valid transaction with secure data handling
    /// Requirements:
    /// - Financial Tracking (1.2 Scope/Financial Tracking)
    /// - Transaction Data Security (6.2.2 Sensitive Data Handling)
    func testSaveTransaction_WithValidData_SavesSuccessfully() {
        // Given
        let expectation = expectation(description: "Save transaction completes")
        let testTransaction = Transaction(
            id: UUID(),
            accountId: UUID(),
            amount: Decimal(100.50),
            description: "Test Transaction",
            type: .debit
        )
        var savedTransaction: Transaction?
        var receivedError: Error?
        
        // When
        sut.saveTransaction(testTransaction)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { transaction in
                    savedTransaction = transaction
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 5.0)
        XCTAssertNil(receivedError, "Should not receive any error")
        XCTAssertNotNil(savedTransaction, "Should receive saved transaction")
        XCTAssertEqual(savedTransaction?.id, testTransaction.id, "Saved transaction should match original ID")
        XCTAssertEqual(savedTransaction?.amount, testTransaction.amount, "Saved transaction should match original amount")
        XCTAssertEqual(savedTransaction?.description, testTransaction.description, "Saved transaction should match original description")
        
        // Verify persistence
        let verifyExpectation = expectation(description: "Verify transaction persistence")
        var retrievedTransactions: [Transaction]?
        
        sut.getTransactions(startDate: nil, endDate: nil, accountId: testTransaction.accountId, categoryId: nil)
            .sink(
                receiveCompletion: { _ in
                    verifyExpectation.fulfill()
                },
                receiveValue: { transactions in
                    retrievedTransactions = transactions
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(retrievedTransactions?.count, 1, "Should retrieve one transaction")
        XCTAssertEqual(retrievedTransactions?.first?.id, testTransaction.id, "Retrieved transaction should match saved transaction")
    }
    
    /// Tests transaction synchronization with secure data handling
    /// Requirements:
    /// - Cross-platform Data Synchronization (1.2 Scope/Account Management)
    /// - Transaction Data Security (6.2.2 Sensitive Data Handling)
    func testSyncTransactions_WithNewData_SyncsSuccessfully() {
        // Given
        let expectation = expectation(description: "Sync transactions completes")
        let testAccountId = UUID()
        var syncedTransactions: [Transaction]?
        var receivedError: Error?
        
        // When
        sut.syncTransactions(accountId: testAccountId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { transactions in
                    syncedTransactions = transactions
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 5.0)
        XCTAssertNil(receivedError, "Should not receive any error")
        XCTAssertNotNil(syncedTransactions, "Should receive synced transactions")
        
        // Verify local persistence of synced data
        let verifyExpectation = expectation(description: "Verify synced data persistence")
        var retrievedTransactions: [Transaction]?
        
        sut.getTransactions(startDate: nil, endDate: nil, accountId: testAccountId, categoryId: nil)
            .sink(
                receiveCompletion: { _ in
                    verifyExpectation.fulfill()
                },
                receiveValue: { transactions in
                    retrievedTransactions = transactions
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(retrievedTransactions?.count, syncedTransactions?.count, "Local transactions should match synced transactions")
    }
}