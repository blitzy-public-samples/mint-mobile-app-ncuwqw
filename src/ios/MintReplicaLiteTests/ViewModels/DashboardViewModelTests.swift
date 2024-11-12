//
// DashboardViewModelTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Configure test timeout values for CI/CD pipeline
// 2. Set up test data fixtures for different account scenarios
// 3. Review mock data to ensure compliance with business rules
// 4. Set up performance testing thresholds

// Third-party Dependencies:
// - XCTest (iOS 14.0+)
// - Combine (iOS 14.0+)

import XCTest
import Combine
@testable import MintReplicaLite

/// Test suite for DashboardViewModel verifying reactive data flow and presentation logic
/// Requirements addressed:
/// - Account Management (1.2): Verify real-time balance updates and account aggregation
/// - Financial Tracking (1.2): Test transaction monitoring and updates
/// - Budget Management (1.2): Validate budget progress monitoring
final class DashboardViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: DashboardViewModel!
    private var mockAccountsUseCase: MockAccountsUseCase!
    private var mockBudgetUseCase: MockBudgetUseCase!
    private var mockTransactionsUseCase: MockTransactionsUseCase!
    private var cancellables: Set<AnyCancellable>!
    
    // Test timeout constant
    private let testTimeout: TimeInterval = 5.0
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        mockAccountsUseCase = MockAccountsUseCase()
        mockBudgetUseCase = MockBudgetUseCase()
        mockTransactionsUseCase = MockTransactionsUseCase()
        sut = DashboardViewModel(
            accountsUseCase: mockAccountsUseCase,
            budgetUseCase: mockBudgetUseCase,
            transactionsUseCase: mockTransactionsUseCase
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        sut = nil
        mockAccountsUseCase = nil
        mockBudgetUseCase = nil
        mockTransactionsUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests proper initialization of view model and initial state
    /// Requirement: Account Management - Verify initial data state
    func testInitialization() {
        let expectation = XCTestExpectation(description: "Initial state verification")
        
        let input = Input(refreshTrigger: Empty().eraseToAnyPublisher())
        let output = sut.transform(input)
        
        output.accounts
            .sink { accounts in
                XCTAssertTrue(accounts.isEmpty, "Initial accounts should be empty")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: testTimeout)
    }
    
    /// Tests dashboard refresh functionality and data updates
    /// Requirements addressed:
    /// - Account Management: Verify real-time balance updates
    /// - Financial Tracking: Test transaction monitoring
    func testRefreshDashboard() {
        let accountsExpectation = XCTestExpectation(description: "Accounts update")
        let transactionsExpectation = XCTestExpectation(description: "Transactions update")
        let budgetExpectation = XCTestExpectation(description: "Budget update")
        
        // Setup test data
        let testAccounts = [
            Account(id: UUID(), name: "Test Checking", institutionId: "test_bank",
                   accountNumber: "1234", type: .checking, balance: 1000.00),
            Account(id: UUID(), name: "Test Savings", institutionId: "test_bank",
                   accountNumber: "5678", type: .savings, balance: 5000.00)
        ]
        mockAccountsUseCase.mockAccounts = testAccounts
        
        let refreshTrigger = PassthroughSubject<Void, Never>()
        let input = Input(refreshTrigger: refreshTrigger.eraseToAnyPublisher())
        let output = sut.transform(input)
        
        output.accounts
            .dropFirst() // Skip initial empty state
            .sink { accounts in
                XCTAssertEqual(accounts.count, 2, "Should receive two test accounts")
                XCTAssertEqual(accounts[0].type, .checking, "First account should be checking")
                XCTAssertEqual(accounts[1].type, .savings, "Second account should be savings")
                accountsExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        output.recentTransactions
            .dropFirst() // Skip initial empty state
            .sink { transactions in
                XCTAssertNotNil(transactions, "Should receive transactions update")
                transactionsExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        output.budgetProgress
            .dropFirst() // Skip initial empty state
            .sink { progress in
                XCTAssertNotNil(progress, "Should receive budget progress update")
                budgetExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        refreshTrigger.send(())
        
        wait(for: [accountsExpectation, transactionsExpectation, budgetExpectation],
             timeout: testTimeout)
    }
    
    /// Tests net worth calculation from account balances
    /// Requirement: Account Management - Verify balance aggregation
    func testNetWorthCalculation() {
        let expectation = XCTestExpectation(description: "Net worth calculation")
        
        // Setup test accounts with known balances
        let testAccounts = [
            Account(id: UUID(), name: "Checking", institutionId: "test_bank",
                   accountNumber: "1234", type: .checking, balance: 1000.00),
            Account(id: UUID(), name: "Savings", institutionId: "test_bank",
                   accountNumber: "5678", type: .savings, balance: 5000.00),
            Account(id: UUID(), name: "Credit Card", institutionId: "test_bank",
                   accountNumber: "9012", type: .credit, balance: 500.00)
        ]
        mockAccountsUseCase.mockAccounts = testAccounts
        
        let refreshTrigger = PassthroughSubject<Void, Never>()
        let input = Input(refreshTrigger: refreshTrigger.eraseToAnyPublisher())
        let output = sut.transform(input)
        
        output.netWorth
            .dropFirst() // Skip initial zero state
            .sink { netWorth in
                // Net worth should be: Checking + Savings - Credit Card
                let expectedNetWorth = Decimal(1000.00 + 5000.00 - 500.00)
                XCTAssertEqual(netWorth, expectedNetWorth,
                             "Net worth calculation should match expected value")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        refreshTrigger.send(())
        
        wait(for: [expectation], timeout: testTimeout)
    }
}

// MARK: - Mock Classes

/// Mock implementation of AccountsUseCase for testing
final class MockAccountsUseCase: AccountsUseCase {
    var mockAccounts: [Account] = []
    
    func getAllAccounts() -> AnyPublisher<[Account], Error> {
        return Just(mockAccounts)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

/// Mock implementation of BudgetUseCase for testing
final class MockBudgetUseCase: BudgetUseCase {
    var mockBudgetProgress: [(Budget, Double)] = []
    
    func getBudgetProgress() -> AnyPublisher<[(Budget, Double)], Error> {
        return Just(mockBudgetProgress)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

/// Mock implementation of TransactionsUseCase for testing
final class MockTransactionsUseCase: TransactionsUseCase {
    var mockTransactions: [Transaction] = []
    
    func getTransactions() -> AnyPublisher<[Transaction], Error> {
        return Just(mockTransactions)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}