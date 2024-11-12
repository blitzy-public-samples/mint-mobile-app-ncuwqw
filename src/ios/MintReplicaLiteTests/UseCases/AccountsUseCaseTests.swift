//
// AccountsUseCaseTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Configure test environment with appropriate test database credentials
// 2. Verify mock data matches production data schema
// 3. Set up CI pipeline test configuration for this test suite
// 4. Review test coverage requirements with QA team

// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

/// Test suite for AccountsUseCase implementation verifying account management business logic
/// Implements:
/// - Account Management Testing (Section 1.2): Verify multi-platform user authentication and financial account aggregation
/// - Data Security Testing (Section 2.4): Validate secure handling of sensitive account information
final class AccountsUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: AccountsUseCase!
    private var mockRepository: MockAccountRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAccountRepository()
        sut = AccountsUseCase(repository: mockRepository)
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
    
    /// Tests successful retrieval of all accounts with proper sorting and filtering
    /// Verifies Account Management requirement for account aggregation
    func testGetAllAccountsSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Get all accounts")
        let testAccounts = [
            Account(id: UUID(), name: "Checking", institutionId: "inst1", accountNumber: "1234", type: .checking, balance: 1000),
            Account(id: UUID(), name: "Savings", institutionId: "inst1", accountNumber: "5678", type: .savings, balance: 5000),
            Account(id: UUID(), name: "Credit Card", institutionId: "inst2", accountNumber: "9012", type: .credit, balance: -500)
        ]
        mockRepository.getAccountsResult = .success(testAccounts)
        
        var receivedAccounts: [Account]?
        var receivedError: Error?
        
        // When
        sut.getAllAccounts()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { accounts in
                    receivedAccounts = accounts
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedError, "Should not receive an error")
        XCTAssertNotNil(receivedAccounts, "Should receive accounts")
        XCTAssertEqual(receivedAccounts?.count, 3, "Should receive all active accounts")
        
        // Verify sorting by type and name
        if let accounts = receivedAccounts {
            XCTAssertEqual(accounts[0].type, .checking)
            XCTAssertEqual(accounts[1].type, .credit)
            XCTAssertEqual(accounts[2].type, .savings)
        }
    }
    
    /// Tests successful account addition with validation
    /// Verifies Data Security requirement for secure account handling
    func testAddAccountSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Add account")
        let testAccount = Account(
            id: UUID(),
            name: "Test Account",
            institutionId: "test_inst",
            accountNumber: "test123",
            type: .checking,
            balance: 1000
        )
        mockRepository.saveAccountResult = .success(testAccount)
        
        var receivedAccount: Account?
        var receivedError: Error?
        
        // When
        sut.addAccount(testAccount)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { account in
                    receivedAccount = account
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedError, "Should not receive an error")
        XCTAssertNotNil(receivedAccount, "Should receive the added account")
        XCTAssertEqual(receivedAccount?.id, testAccount.id)
        XCTAssertEqual(receivedAccount?.name, testAccount.name)
        XCTAssertEqual(receivedAccount?.accountNumber, testAccount.accountNumber)
        XCTAssertTrue(receivedAccount?.isActive ?? false)
    }
    
    /// Tests successful account update with validation
    /// Verifies Account Management requirement for account updates
    func testUpdateAccountSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Update account")
        let testAccount = Account(
            id: UUID(),
            name: "Updated Account",
            institutionId: "test_inst",
            accountNumber: "test123",
            type: .checking,
            balance: 2000
        )
        mockRepository.saveAccountResult = .success(testAccount)
        mockRepository.getAccountResult = .success(testAccount)
        
        var receivedAccount: Account?
        var receivedError: Error?
        
        // When
        sut.updateAccount(testAccount)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { account in
                    receivedAccount = account
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedError, "Should not receive an error")
        XCTAssertNotNil(receivedAccount, "Should receive the updated account")
        XCTAssertEqual(receivedAccount?.id, testAccount.id)
        XCTAssertEqual(receivedAccount?.name, testAccount.name)
        XCTAssertEqual(receivedAccount?.balance, testAccount.balance)
    }
    
    /// Tests successful account removal with validation
    /// Verifies Data Security requirement for secure account deletion
    func testRemoveAccountSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Remove account")
        let accountId = UUID()
        let testAccount = Account(
            id: accountId,
            name: "Test Account",
            institutionId: "test_inst",
            accountNumber: "test123",
            type: .checking,
            balance: 1000
        )
        mockRepository.getAccountResult = .success(testAccount)
        mockRepository.deleteAccountResult = .success(())
        
        var receivedError: Error?
        var completed = false
        
        // When
        sut.removeAccount(id: accountId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    } else {
                        completed = true
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedError, "Should not receive an error")
        XCTAssertTrue(completed, "Should complete successfully")
        XCTAssertTrue(mockRepository.deleteAccountCalled)
        XCTAssertEqual(mockRepository.lastDeletedAccountId, accountId)
    }
    
    /// Tests successful account synchronization
    /// Verifies Account Management requirement for account aggregation
    func testSyncAccountsSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Sync accounts")
        let testAccounts = [
            Account(id: UUID(), name: "Synced Checking", institutionId: "inst1", accountNumber: "1234", type: .checking, balance: 1500),
            Account(id: UUID(), name: "Synced Savings", institutionId: "inst1", accountNumber: "5678", type: .savings, balance: 5500)
        ]
        mockRepository.syncAccountsResult = .success(testAccounts)
        
        var receivedAccounts: [Account]?
        var receivedError: Error?
        
        // When
        sut.syncAccounts()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { accounts in
                    receivedAccounts = accounts
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedError, "Should not receive an error")
        XCTAssertNotNil(receivedAccounts, "Should receive synced accounts")
        XCTAssertEqual(receivedAccounts?.count, testAccounts.count)
        XCTAssertTrue(mockRepository.syncAccountsCalled)
        
        // Verify account properties after sync
        if let accounts = receivedAccounts {
            for (index, account) in accounts.enumerated() {
                XCTAssertEqual(account.id, testAccounts[index].id)
                XCTAssertEqual(account.balance, testAccounts[index].balance)
                XCTAssertTrue(account.isActive)
            }
        }
    }
}

// MARK: - Mock Repository

private class MockAccountRepository: AccountRepository {
    var getAccountsResult: Result<[Account], Error> = .success([])
    var getAccountResult: Result<Account?, Error> = .success(nil)
    var saveAccountResult: Result<Account, Error> = .success(Account(id: UUID(), name: "", institutionId: "", accountNumber: "", type: .checking, balance: 0))
    var deleteAccountResult: Result<Void, Error> = .success(())
    var syncAccountsResult: Result<[Account], Error> = .success([])
    
    var getAccountsCalled = false
    var getAccountCalled = false
    var saveAccountCalled = false
    var deleteAccountCalled = false
    var syncAccountsCalled = false
    
    var lastDeletedAccountId: UUID?
    var lastSavedAccount: Account?
    
    func getAccounts() -> AnyPublisher<[Account], Error> {
        getAccountsCalled = true
        return Result.Publisher(getAccountsResult).eraseToAnyPublisher()
    }
    
    func getAccount(id: UUID) -> AnyPublisher<Account?, Error> {
        getAccountCalled = true
        return Result.Publisher(getAccountResult).eraseToAnyPublisher()
    }
    
    func saveAccount(_ account: Account) -> AnyPublisher<Account, Error> {
        saveAccountCalled = true
        lastSavedAccount = account
        return Result.Publisher(saveAccountResult).eraseToAnyPublisher()
    }
    
    func deleteAccount(id: UUID) -> AnyPublisher<Void, Error> {
        deleteAccountCalled = true
        lastDeletedAccountId = id
        return Result.Publisher(deleteAccountResult).eraseToAnyPublisher()
    }
    
    func syncAccounts() -> AnyPublisher<[Account], Error> {
        syncAccountsCalled = true
        return Result.Publisher(syncAccountsResult).eraseToAnyPublisher()
    }
}