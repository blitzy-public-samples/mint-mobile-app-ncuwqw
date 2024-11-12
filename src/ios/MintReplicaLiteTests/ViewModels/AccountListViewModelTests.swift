//
// AccountListViewModelTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Verify test coverage meets minimum 85% requirement
// 2. Add performance tests for large account lists
// 3. Configure CI pipeline test thresholds
// 4. Review test data with compliance team

// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

/// Test suite for AccountListViewModel verifying MVVM presentation logic and Combine data flow
/// Tests implementation of:
/// - Account Management (Section 1.2): Multi-platform user authentication and financial account aggregation
/// - Financial Tracking (Section 1.2): Account balance monitoring and management functionality
final class AccountListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: AccountListViewModel!
    private var mockUseCase: MockAccountsUseCase!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockAccountsUseCase()
        sut = AccountListViewModel(accountsUseCase: mockUseCase)
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
    
    /// Tests initial view model state after initialization
    /// Verifies Account Management requirement for proper initialization
    func testInitialState() {
        // Given
        var loadingState = false
        var accounts: [Account] = [Account]()
        var error: Error?
        
        // When
        let output = sut.transform(.viewDidLoad)
        
        // Then
        switch output {
        case .loading(let isLoading):
            loadingState = isLoading
        case .accounts(let accountList):
            accounts = accountList
        case .error(let receivedError):
            error = receivedError
        }
        
        XCTAssertFalse(loadingState, "Initial loading state should be false")
        XCTAssertTrue(accounts.isEmpty, "Initial accounts array should be empty")
        XCTAssertNil(error, "Initial error should be nil")
    }
    
    /// Tests successful account loading flow
    /// Verifies Account Management requirement for account aggregation
    func testLoadAccountsSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Load accounts")
        var loadingStates: [Bool] = []
        var receivedAccounts: [Account] = []
        
        let mockAccounts = [
            Account(id: UUID(),
                   name: "Test Checking",
                   institutionId: "test_bank",
                   accountNumber: "1234",
                   type: .checking,
                   balance: 1000.0),
            Account(id: UUID(),
                   name: "Test Savings",
                   institutionId: "test_bank",
                   accountNumber: "5678",
                   type: .savings,
                   balance: 5000.0)
        ]
        
        mockUseCase.mockGetAllAccountsResult = Just(mockAccounts)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        
        // When
        let output = sut.transform(.viewDidLoad)
        
        // Then
        switch output {
        case .loading(let isLoading):
            loadingStates.append(isLoading)
        case .accounts(let accounts):
            receivedAccounts = accounts
            expectation.fulfill()
        case .error:
            XCTFail("Should not receive error for successful load")
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedAccounts.count, mockAccounts.count, "Should receive correct number of accounts")
        XCTAssertEqual(receivedAccounts.first?.name, mockAccounts.first?.name, "Account data should match")
        XCTAssertEqual(receivedAccounts.first?.balance, mockAccounts.first?.balance, "Account balance should match")
    }
    
    /// Tests account loading error handling
    /// Verifies Account Management requirement for error handling
    func testLoadAccountsFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Load accounts error")
        let expectedError = NSError(domain: "test", code: -1, userInfo: nil)
        var receivedError: Error?
        
        mockUseCase.mockGetAllAccountsResult = Fail(error: expectedError)
            .eraseToAnyPublisher()
        
        // When
        let output = sut.transform(.viewDidLoad)
        
        // Then
        switch output {
        case .loading:
            break
        case .accounts:
            XCTFail("Should not receive accounts for failed load")
        case .error(let error):
            receivedError = error
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNotNil(receivedError, "Should receive error")
        XCTAssertEqual((receivedError as NSError?)?.domain, expectedError.domain, "Error should match expected error")
    }
    
    /// Tests account refresh functionality
    /// Verifies Financial Tracking requirement for account balance updates
    func testRefreshAccounts() {
        // Given
        let expectation = XCTestExpectation(description: "Refresh accounts")
        var receivedAccounts: [Account] = []
        
        let mockAccounts = [
            Account(id: UUID(),
                   name: "Updated Checking",
                   institutionId: "test_bank",
                   accountNumber: "1234",
                   type: .checking,
                   balance: 1500.0)
        ]
        
        mockUseCase.mockSyncAccountsResult = Just(mockAccounts)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        
        // When
        let output = sut.transform(.refresh)
        
        // Then
        switch output {
        case .loading:
            break
        case .accounts(let accounts):
            receivedAccounts = accounts
            expectation.fulfill()
        case .error:
            XCTFail("Should not receive error for successful refresh")
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedAccounts.count, mockAccounts.count, "Should receive updated accounts")
        XCTAssertEqual(receivedAccounts.first?.balance, mockAccounts.first?.balance, "Account balance should be updated")
    }
    
    /// Tests account deletion flow
    /// Verifies Account Management requirement for account operations
    func testDeleteAccount() {
        // Given
        let expectation = XCTestExpectation(description: "Delete account")
        let accountId = UUID()
        var deletionSuccessful = false
        
        mockUseCase.mockRemoveAccountResult = Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        
        // When
        let output = sut.transform(.deleteAccount(accountId))
        
        // Then
        switch output {
        case .loading:
            break
        case .accounts:
            deletionSuccessful = true
            expectation.fulfill()
        case .error:
            XCTFail("Should not receive error for successful deletion")
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(deletionSuccessful, "Account deletion should complete successfully")
    }
}

// MARK: - Mock AccountsUseCase

/// Mock implementation of AccountsUseCaseProtocol for testing
final class MockAccountsUseCase: AccountsUseCaseProtocol {
    var mockGetAllAccountsResult: AnyPublisher<[Account], Error>!
    var mockSyncAccountsResult: AnyPublisher<[Account], Error>!
    var mockRemoveAccountResult: AnyPublisher<Void, Error>!
    
    func getAllAccounts() -> AnyPublisher<[Account], Error> {
        return mockGetAllAccountsResult
    }
    
    func syncAccounts() -> AnyPublisher<[Account], Error> {
        return mockSyncAccountsResult
    }
    
    func removeAccount(id: UUID) -> AnyPublisher<Void, Error> {
        return mockRemoveAccountResult
    }
}