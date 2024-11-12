// HUMAN TASKS:
// 1. Verify XCTest framework is properly linked in project settings
// 2. Ensure minimum iOS deployment target is set to iOS 14.0+
// 3. Configure test coverage reporting in Xcode scheme settings
// 4. Review mock data values with product team for realistic test scenarios

// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

/// Test suite for TransactionListViewModel verifying transaction management functionality
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking): Verify transaction search, filtering, and secure data handling
/// - Cross-platform Data Synchronization (1.2 Scope/Account Management): Test real-time balance updates
final class TransactionListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: TransactionListViewModel!
    private var mockUseCase: MockTransactionsUseCase!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockTransactionsUseCase()
        sut = TransactionListViewModel(transactionsUseCase: mockUseCase)
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
    
    func testInitialState() {
        // Given
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let refreshTriggered = PassthroughSubject<Void, Never>()
        let filterSelected = PassthroughSubject<TransactionFilter?, Never>()
        let sortSelected = PassthroughSubject<TransactionSort?, Never>()
        
        let input = TransactionListViewModel.Input(
            viewDidLoad: viewDidLoad.eraseToAnyPublisher(),
            refreshTriggered: refreshTriggered.eraseToAnyPublisher(),
            filterSelected: filterSelected.eraseToAnyPublisher(),
            sortSelected: sortSelected.eraseToAnyPublisher()
        )
        
        // When
        let output = sut.transform(input)
        
        var transactions: [Transaction] = []
        var isLoading = false
        var error: Error?
        
        output.transactions.sink { transactions = $0 }.store(in: &cancellables)
        output.isLoading.sink { isLoading = $0 }.store(in: &cancellables)
        output.error.sink { error = $0 }.store(in: &cancellables)
        
        // Then
        XCTAssertTrue(transactions.isEmpty)
        XCTAssertFalse(isLoading)
        XCTAssertNil(error)
    }
    
    func testFetchTransactionsSuccess() {
        // Given
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let input = TransactionListViewModel.Input(
            viewDidLoad: viewDidLoad.eraseToAnyPublisher(),
            refreshTriggered: Empty().eraseToAnyPublisher(),
            filterSelected: Empty().eraseToAnyPublisher(),
            sortSelected: Empty().eraseToAnyPublisher()
        )
        
        let mockTransactions = [
            Transaction(id: UUID(), accountId: UUID(), amount: 100.0, description: "Test 1", type: .debit),
            Transaction(id: UUID(), accountId: UUID(), amount: 200.0, description: "Test 2", type: .credit)
        ]
        mockUseCase.mockTransactions = mockTransactions
        
        var receivedTransactions: [Transaction] = []
        var loadingStates: [Bool] = []
        var receivedError: Error?
        
        let output = sut.transform(input)
        
        output.transactions.sink { receivedTransactions = $0 }.store(in: &cancellables)
        output.isLoading.sink { loadingStates.append($0) }.store(in: &cancellables)
        output.error.sink { receivedError = $0 }.store(in: &cancellables)
        
        // When
        viewDidLoad.send(())
        
        // Then
        XCTAssertEqual(receivedTransactions.count, mockTransactions.count)
        XCTAssertEqual(loadingStates, [false, true, false])
        XCTAssertNil(receivedError)
    }
    
    func testFetchTransactionsFailure() {
        // Given
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let input = TransactionListViewModel.Input(
            viewDidLoad: viewDidLoad.eraseToAnyPublisher(),
            refreshTriggered: Empty().eraseToAnyPublisher(),
            filterSelected: Empty().eraseToAnyPublisher(),
            sortSelected: Empty().eraseToAnyPublisher()
        )
        
        let expectedError = NSError(domain: "test", code: -1, userInfo: nil)
        mockUseCase.mockError = expectedError
        
        var receivedTransactions: [Transaction] = []
        var loadingStates: [Bool] = []
        var receivedError: Error?
        
        let output = sut.transform(input)
        
        output.transactions.sink { receivedTransactions = $0 }.store(in: &cancellables)
        output.isLoading.sink { loadingStates.append($0) }.store(in: &cancellables)
        output.error.sink { receivedError = $0 }.store(in: &cancellables)
        
        // When
        viewDidLoad.send(())
        
        // Then
        XCTAssertTrue(receivedTransactions.isEmpty)
        XCTAssertEqual(loadingStates, [false, true, false])
        XCTAssertEqual((receivedError as NSError?)?.domain, expectedError.domain)
    }
    
    func testTransactionFiltering() {
        // Given
        let filterSelected = PassthroughSubject<TransactionFilter?, Never>()
        let input = TransactionListViewModel.Input(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            refreshTriggered: Empty().eraseToAnyPublisher(),
            filterSelected: filterSelected.eraseToAnyPublisher(),
            sortSelected: Empty().eraseToAnyPublisher()
        )
        
        let mockTransactions = [
            Transaction(id: UUID(), accountId: UUID(), amount: 100.0, description: "Test 1", type: .debit)
        ]
        mockUseCase.mockTransactions = mockTransactions
        
        var receivedTransactions: [Transaction] = []
        var loadingStates: [Bool] = []
        
        let output = sut.transform(input)
        
        output.transactions.sink { receivedTransactions = $0 }.store(in: &cancellables)
        output.isLoading.sink { loadingStates.append($0) }.store(in: &cancellables)
        
        // When
        let filter = TransactionFilter(
            dateRange: nil,
            amountRange: TransactionFilter.AmountRange(min: 50.0, max: 150.0),
            accountId: nil,
            categoryId: nil,
            types: [.debit],
            status: nil
        )
        filterSelected.send(filter)
        
        // Then
        XCTAssertEqual(receivedTransactions.count, mockTransactions.count)
        XCTAssertEqual(loadingStates, [false, true, false])
    }
    
    func testTransactionSorting() {
        // Given
        let sortSelected = PassthroughSubject<TransactionSort?, Never>()
        let input = TransactionListViewModel.Input(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            refreshTriggered: Empty().eraseToAnyPublisher(),
            filterSelected: Empty().eraseToAnyPublisher(),
            sortSelected: sortSelected.eraseToAnyPublisher()
        )
        
        let mockTransactions = [
            Transaction(id: UUID(), accountId: UUID(), amount: 200.0, description: "Test 2", type: .credit),
            Transaction(id: UUID(), accountId: UUID(), amount: 100.0, description: "Test 1", type: .debit)
        ]
        mockUseCase.mockTransactions = mockTransactions
        
        var receivedTransactions: [Transaction] = []
        var loadingStates: [Bool] = []
        
        let output = sut.transform(input)
        
        output.transactions.sink { receivedTransactions = $0 }.store(in: &cancellables)
        output.isLoading.sink { loadingStates.append($0) }.store(in: &cancellables)
        
        // When
        let sort = TransactionSort(criteria: .amount, ascending: true)
        sortSelected.send(sort)
        
        // Then
        XCTAssertEqual(receivedTransactions.count, mockTransactions.count)
        XCTAssertEqual(loadingStates, [false, true, false])
    }
    
    func testSyncTransactions() {
        // Given
        let refreshTriggered = PassthroughSubject<Void, Never>()
        let input = TransactionListViewModel.Input(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            refreshTriggered: refreshTriggered.eraseToAnyPublisher(),
            filterSelected: Empty().eraseToAnyPublisher(),
            sortSelected: Empty().eraseToAnyPublisher()
        )
        
        let mockTransactions = [
            Transaction(id: UUID(), accountId: UUID(), amount: 100.0, description: "Synced 1", type: .debit),
            Transaction(id: UUID(), accountId: UUID(), amount: 200.0, description: "Synced 2", type: .credit)
        ]
        mockUseCase.mockTransactions = mockTransactions
        
        var receivedTransactions: [Transaction] = []
        var loadingStates: [Bool] = []
        var receivedError: Error?
        
        let output = sut.transform(input)
        
        output.transactions.sink { receivedTransactions = $0 }.store(in: &cancellables)
        output.isLoading.sink { loadingStates.append($0) }.store(in: &cancellables)
        output.error.sink { receivedError = $0 }.store(in: &cancellables)
        
        // When
        refreshTriggered.send(())
        
        // Then
        XCTAssertEqual(receivedTransactions.count, mockTransactions.count)
        XCTAssertEqual(loadingStates, [false, true, false])
        XCTAssertNil(receivedError)
    }
}

// MARK: - Mock Implementation

final class MockTransactionsUseCase: TransactionsUseCaseProtocol {
    var mockTransactions: [Transaction] = []
    var mockError: Error?
    
    func getTransactions(filter: TransactionFilter?, sort: TransactionSort?) -> AnyPublisher<[Transaction], Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(mockTransactions)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func syncTransactions(accountId: UUID) -> AnyPublisher<[Transaction], Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(mockTransactions)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}