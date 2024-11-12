//
// AccountRepositoryTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Configure test environment variables for mock API responses
// 2. Set up test database with appropriate encryption keys
// 3. Verify SSL certificate pinning configuration for test environment
// 4. Review test coverage requirements with security team

// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
// Foundation framework - iOS 14.0+
import Foundation
// Import app module for testing
@testable import MintReplicaLite

/// Test suite for AccountRepository implementation verifying secure data operations and synchronization
/// Implements:
/// - Account Management requirement (Section 1.2): Testing multi-platform account aggregation
/// - Data Security requirement (Section 2.4): Verifying secure data handling
final class AccountRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    
    /// System under test - AccountRepository instance
    private var sut: AccountRepository!
    /// Set to store and manage Combine subscriptions
    private var cancellables: Set<AnyCancellable>!
    /// Test timeout duration
    private let testTimeout: TimeInterval = 5.0
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        // Initialize empty cancellables set for subscription management
        cancellables = Set<AnyCancellable>()
        // Clear Core Data database before each test
        CoreDataManager.shared.clearDatabase()
        // Initialize system under test
        sut = AccountRepository()
    }
    
    override func tearDown() {
        // Cancel all active publishers
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        // Clear database after each test
        CoreDataManager.shared.clearDatabase()
        // Clean up system under test
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests saving a new account with secure field-level encryption
    /// Verifies Account Management requirement for secure account creation
    func testSaveAccount() {
        // Given
        let expectation = expectation(description: "Save account")
        let testAccount = Account(
            id: UUID(),
            name: "Test Checking",
            institutionId: "test_bank_123",
            accountNumber: "****1234",
            type: .checking,
            balance: 1000.50
        )
        var savedAccount: Account?
        var error: Error?
        
        // When
        sut.saveAccount(testAccount)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let err) = completion {
                        error = err
                    }
                    expectation.fulfill()
                },
                receiveValue: { account in
                    savedAccount = account
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: testTimeout)
        
        XCTAssertNil(error, "Saving account should not produce an error")
        XCTAssertNotNil(savedAccount, "Saved account should not be nil")
        XCTAssertEqual(savedAccount?.id, testAccount.id, "Account ID should match")
        XCTAssertEqual(savedAccount?.name, testAccount.name, "Account name should match")
        XCTAssertEqual(savedAccount?.institutionId, testAccount.institutionId, "Institution ID should match")
        XCTAssertEqual(savedAccount?.accountNumber, testAccount.accountNumber, "Account number should be encrypted")
        XCTAssertEqual(savedAccount?.type, testAccount.type, "Account type should match")
        XCTAssertEqual(savedAccount?.balance, testAccount.balance, "Balance should match")
        XCTAssertTrue(savedAccount?.isActive ?? false, "Account should be active")
    }
    
    /// Tests retrieving all accounts with proper decryption
    /// Verifies Data Security requirement for secure data retrieval
    func testGetAccounts() {
        // Given
        let expectation = expectation(description: "Get accounts")
        let testAccounts = [
            Account(id: UUID(), name: "Checking", institutionId: "bank_1", accountNumber: "****1234", type: .checking, balance: 1000.00),
            Account(id: UUID(), name: "Savings", institutionId: "bank_1", accountNumber: "****5678", type: .savings, balance: 5000.00),
            Account(id: UUID(), name: "Credit Card", institutionId: "bank_2", accountNumber: "****9012", type: .credit, balance: -500.00)
        ]
        var retrievedAccounts: [Account] = []
        var error: Error?
        
        // Save test accounts first
        let saveExpectation = expectation(description: "Save test accounts")
        saveExpectation.expectedFulfillmentCount = testAccounts.count
        
        testAccounts.forEach { account in
            sut.saveAccount(account)
                .sink(
                    receiveCompletion: { _ in
                        saveExpectation.fulfill()
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
        
        wait(for: [saveExpectation], timeout: testTimeout)
        
        // When
        sut.getAccounts()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let err) = completion {
                        error = err
                    }
                    expectation.fulfill()
                },
                receiveValue: { accounts in
                    retrievedAccounts = accounts
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: testTimeout)
        
        XCTAssertNil(error, "Getting accounts should not produce an error")
        XCTAssertEqual(retrievedAccounts.count, testAccounts.count, "Should retrieve all saved accounts")
        
        // Verify each account was retrieved correctly
        testAccounts.forEach { testAccount in
            XCTAssertTrue(
                retrievedAccounts.contains { account in
                    account.id == testAccount.id &&
                    account.name == testAccount.name &&
                    account.institutionId == testAccount.institutionId &&
                    account.accountNumber == testAccount.accountNumber &&
                    account.type == testAccount.type &&
                    account.balance == testAccount.balance
                },
                "Retrieved accounts should contain test account with ID: \(testAccount.id)"
            )
        }
    }
    
    /// Tests secure deletion of account data
    /// Verifies Data Security requirement for secure data removal
    func testDeleteAccount() {
        // Given
        let saveExpectation = expectation(description: "Save account")
        let deleteExpectation = expectation(description: "Delete account")
        let verifyExpectation = expectation(description: "Verify deletion")
        
        let testAccount = Account(
            id: UUID(),
            name: "Test Account",
            institutionId: "test_bank",
            accountNumber: "****4321",
            type: .checking,
            balance: 1500.00
        )
        
        var error: Error?
        
        // Save test account first
        sut.saveAccount(testAccount)
            .sink(
                receiveCompletion: { _ in
                    saveExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: testTimeout)
        
        // When
        sut.deleteAccount(id: testAccount.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let err) = completion {
                        error = err
                    }
                    deleteExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [deleteExpectation], timeout: testTimeout)
        
        // Verify account was deleted
        sut.getAccount(id: testAccount.id)
            .sink(
                receiveCompletion: { _ in
                    verifyExpectation.fulfill()
                },
                receiveValue: { account in
                    XCTAssertNil(account, "Account should be deleted")
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [verifyExpectation], timeout: testTimeout)
        XCTAssertNil(error, "Deleting account should not produce an error")
    }
    
    /// Tests account synchronization with secure remote updates
    /// Verifies Account Management requirement for secure synchronization
    func testSyncAccounts() {
        // Given
        let expectation = expectation(description: "Sync accounts")
        let testAccounts = [
            Account(id: UUID(), name: "Remote Checking", institutionId: "bank_1", accountNumber: "****1111", type: .checking, balance: 2000.00),
            Account(id: UUID(), name: "Remote Savings", institutionId: "bank_1", accountNumber: "****2222", type: .savings, balance: 10000.00)
        ]
        var syncedAccounts: [Account] = []
        var error: Error?
        
        // When
        sut.syncAccounts()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let err) = completion {
                        error = err
                    }
                    expectation.fulfill()
                },
                receiveValue: { accounts in
                    syncedAccounts = accounts
                }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: testTimeout)
        
        XCTAssertNil(error, "Syncing accounts should not produce an error")
        XCTAssertFalse(syncedAccounts.isEmpty, "Synced accounts should not be empty")
        
        // Verify synced accounts are properly stored
        let verifyExpectation = expectation(description: "Verify synced accounts")
        
        sut.getAccounts()
            .sink(
                receiveCompletion: { _ in
                    verifyExpectation.fulfill()
                },
                receiveValue: { accounts in
                    XCTAssertEqual(accounts.count, syncedAccounts.count, "Local storage should match synced accounts")
                    
                    syncedAccounts.forEach { syncedAccount in
                        XCTAssertTrue(
                            accounts.contains { account in
                                account.id == syncedAccount.id &&
                                account.name == syncedAccount.name &&
                                account.institutionId == syncedAccount.institutionId &&
                                account.accountNumber == syncedAccount.accountNumber &&
                                account.type == syncedAccount.type &&
                                account.balance == syncedAccount.balance &&
                                account.lastSyncDate > Date().addingTimeInterval(-60) // Sync date should be recent
                            },
                            "Local storage should contain synced account with ID: \(syncedAccount.id)"
                        )
                    }
                }
            )
            .store(in: &cancellables)
        
        wait(for: [verifyExpectation], timeout: testTimeout)
    }
}