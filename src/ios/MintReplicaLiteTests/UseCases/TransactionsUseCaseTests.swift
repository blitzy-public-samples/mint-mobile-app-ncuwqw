// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

/// Unit tests for TransactionsUseCase implementation
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking): Transaction management and filtering
/// - Cross-platform Data Synchronization (1.2 Scope/Account Management): Real-time sync
final class TransactionsUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockRepository: MockTransactionRepository!
    private var sut: TransactionsUseCase!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockTransactionRepository()
        sut = TransactionsUseCase(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testGetTransactions() {
        // Given
        let expectation = XCTestExpectation(description: "Get transactions")
        let testAccount = UUID()
        let testCategory = UUID()
        let testTransaction = Transaction(
            id: UUID(),
            accountId: testAccount,
            amount: 100.50,
            description: "Test Transaction",
            type: .debit
        )
        testTransaction.updateCategory(testCategory)
        mockRepository.mockTransactions = [testTransaction]
        
        let filter = TransactionFilter(
            dateRange: nil,
            amountRange: nil,
            accountId: testAccount,
            categoryId: testCategory,
            types: [.debit],
            status: .pending
        )
        
        // When
        sut.getTransactions(filter: filter, sort: nil)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { transactions in
                    // Then
                    XCTAssertEqual(transactions.count, 1)
                    XCTAssertEqual(transactions.first?.id, testTransaction.id)
                    XCTAssertEqual(transactions.first?.accountId, testAccount)
                    XCTAssertEqual(transactions.first?.categoryId, testCategory)
                    XCTAssertEqual(transactions.first?.amount, 100.50)
                    XCTAssertEqual(transactions.first?.type, .debit)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCreateTransaction() {
        // Given
        let expectation = XCTestExpectation(description: "Create transaction")
        let testAccount = UUID()
        let testCategory = UUID()
        
        // When
        sut.createTransaction(
            accountId: testAccount,
            amount: 50.25,
            description: "New Transaction",
            type: .credit,
            categoryId: testCategory
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected error: \(error)")
                }
            },
            receiveValue: { transaction in
                // Then
                XCTAssertEqual(transaction.accountId, testAccount)
                XCTAssertEqual(transaction.amount, 50.25)
                XCTAssertEqual(transaction.description, "New Transaction")
                XCTAssertEqual(transaction.type, .credit)
                XCTAssertEqual(transaction.categoryId, testCategory)
                XCTAssertEqual(transaction.status, .pending)
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateTransaction() {
        // Given
        let expectation = XCTestExpectation(description: "Update transaction")
        let testTransaction = Transaction(
            id: UUID(),
            accountId: UUID(),
            amount: 75.00,
            description: "Original Transaction",
            type: .debit
        )
        mockRepository.mockTransactions = [testTransaction]
        
        // When
        testTransaction.updateStatus(.cleared)
        sut.updateTransaction(testTransaction)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { updatedTransaction in
                    // Then
                    XCTAssertEqual(updatedTransaction.id, testTransaction.id)
                    XCTAssertEqual(updatedTransaction.status, .cleared)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSyncTransactions() {
        // Given
        let expectation = XCTestExpectation(description: "Sync transactions")
        let testAccount = UUID()
        let testTransactions = [
            Transaction(
                id: UUID(),
                accountId: testAccount,
                amount: 100.00,
                description: "Sync Test 1",
                type: .credit
            ),
            Transaction(
                id: UUID(),
                accountId: testAccount,
                amount: 200.00,
                description: "Sync Test 2",
                type: .debit
            )
        ]
        mockRepository.mockTransactions = testTransactions
        
        // When
        sut.syncTransactions(accountId: testAccount)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { syncedTransactions in
                    // Then
                    XCTAssertEqual(syncedTransactions.count, 2)
                    XCTAssertEqual(
                        syncedTransactions.map { $0.id }.sorted(),
                        testTransactions.map { $0.id }.sorted()
                    )
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetTransactionsWithError() {
        // Given
        let expectation = XCTestExpectation(description: "Get transactions error")
        let testError = NSError(domain: "TestError", code: -1)
        mockRepository.mockError = testError
        
        // When
        sut.getTransactions(filter: nil, sort: nil)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertEqual((error as NSError).domain, testError.domain)
                        XCTAssertEqual((error as NSError).code, testError.code)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected error but received value")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Repository

/// Mock implementation of TransactionRepositoryProtocol for testing
final class MockTransactionRepository: TransactionRepositoryProtocol {
    var mockTransactions: [Transaction] = []
    var mockError: Error?
    var cancellables = Set<AnyCancellable>()
    
    func getTransactions(
        startDate: Date?,
        endDate: Date?,
        accountId: UUID?,
        categoryId: UUID?
    ) -> AnyPublisher<[Transaction], Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        var filtered = mockTransactions
        
        if let accountId = accountId {
            filtered = filtered.filter { $0.accountId == accountId }
        }
        
        if let categoryId = categoryId {
            filtered = filtered.filter { $0.categoryId == categoryId }
        }
        
        if let startDate = startDate {
            filtered = filtered.filter { $0.date >= startDate }
        }
        
        if let endDate = endDate {
            filtered = filtered.filter { $0.date <= endDate }
        }
        
        return Just(filtered)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func saveTransaction(_ transaction: Transaction) -> AnyPublisher<Transaction, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        if let index = mockTransactions.firstIndex(where: { $0.id == transaction.id }) {
            mockTransactions[index] = transaction
        } else {
            mockTransactions.append(transaction)
        }
        
        return Just(transaction)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func syncTransactions(accountId: UUID) -> AnyPublisher<[Transaction], Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        let filtered = mockTransactions.filter { $0.accountId == accountId }
        return Just(filtered)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}