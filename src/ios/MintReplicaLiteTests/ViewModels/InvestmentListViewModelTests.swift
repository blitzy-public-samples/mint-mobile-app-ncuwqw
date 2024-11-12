//
// InvestmentListViewModelTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Verify test coverage meets minimum 85% requirement
// 2. Add additional edge cases for error scenarios
// 3. Review memory management in async test cases
// 4. Add performance tests for large investment lists

// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

/// Test suite for InvestmentListViewModel verifying portfolio loading, metrics calculation, and user interactions
/// Implements:
/// - Investment Tracking (1.2): Tests for portfolio monitoring and performance metrics
/// - Client Architecture (2.2.1): Validates MVVM pattern implementation
final class InvestmentListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: InvestmentListViewModel!
    private var mockUseCase: MockInvestmentUseCase!
    private var cancellables: Set<AnyCancellable>!
    private var testAccountId: UUID!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockInvestmentUseCase()
        sut = InvestmentListViewModel(useCase: mockUseCase)
        cancellables = Set<AnyCancellable>()
        testAccountId = UUID()
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        mockUseCase = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests successful portfolio loading with mock investments
    /// Verifies Investment Tracking requirement for portfolio monitoring
    func testLoadPortfolioSuccess() {
        // Given
        let mockInvestments = [
            Investment(id: UUID(),
                      accountId: testAccountId,
                      symbol: "AAPL",
                      name: "Apple Inc.",
                      type: .stock,
                      shares: 10,
                      costBasis: 1500,
                      currentPrice: 150),
            Investment(id: UUID(),
                      accountId: testAccountId,
                      symbol: "GOOGL",
                      name: "Alphabet Inc.",
                      type: .stock,
                      shares: 5,
                      costBasis: 2500,
                      currentPrice: 500)
        ]
        
        mockUseCase.portfolioResult = .success(mockInvestments)
        
        let loadTrigger = PassthroughSubject<UUID, Never>()
        let input = InvestmentListViewModel.Input(
            loadPortfolioTrigger: loadTrigger.eraseToAnyPublisher(),
            refreshTrigger: Empty().eraseToAnyPublisher(),
            investmentSelection: Empty().eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        var receivedInvestments: [Investment]?
        var loadingStates: [Bool] = []
        var receivedError: Error?
        
        output.investments
            .sink { investments in
                receivedInvestments = investments
            }
            .store(in: &cancellables)
        
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.error
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)
        
        // When
        loadTrigger.send(testAccountId)
        
        // Then
        XCTAssertEqual(receivedInvestments?.count, mockInvestments.count)
        XCTAssertEqual(receivedInvestments?[0].symbol, "AAPL")
        XCTAssertEqual(receivedInvestments?[1].symbol, "GOOGL")
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertNil(receivedError)
    }
    
    /// Tests portfolio loading error handling
    /// Verifies Investment Tracking requirement for error handling
    func testLoadPortfolioFailure() {
        // Given
        struct TestError: Error {}
        let expectedError = TestError()
        mockUseCase.portfolioResult = .failure(expectedError)
        
        let loadTrigger = PassthroughSubject<UUID, Never>()
        let input = InvestmentListViewModel.Input(
            loadPortfolioTrigger: loadTrigger.eraseToAnyPublisher(),
            refreshTrigger: Empty().eraseToAnyPublisher(),
            investmentSelection: Empty().eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        var receivedInvestments: [Investment]?
        var loadingStates: [Bool] = []
        var receivedError: Error?
        
        output.investments
            .sink { investments in
                receivedInvestments = investments
            }
            .store(in: &cancellables)
        
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.error
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)
        
        // When
        loadTrigger.send(testAccountId)
        
        // Then
        XCTAssertEqual(receivedInvestments?.count, 0)
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertNotNil(receivedError)
        XCTAssert(receivedError is TestError)
    }
    
    /// Tests successful portfolio metrics loading
    /// Verifies Investment Tracking requirement for performance metrics
    func testLoadPortfolioMetricsSuccess() {
        // Given
        let mockMetrics = PortfolioMetrics(
            totalValue: 10000,
            totalReturn: 2000,
            returnPercentage: 20,
            numberOfInvestments: 2
        )
        
        mockUseCase.metricsResult = .success(mockMetrics)
        mockUseCase.portfolioResult = .success([]) // Empty portfolio to focus on metrics
        
        let loadTrigger = PassthroughSubject<UUID, Never>()
        let input = InvestmentListViewModel.Input(
            loadPortfolioTrigger: loadTrigger.eraseToAnyPublisher(),
            refreshTrigger: Empty().eraseToAnyPublisher(),
            investmentSelection: Empty().eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        var receivedMetrics: PortfolioMetrics?
        var receivedError: Error?
        
        output.portfolioMetrics
            .sink { metrics in
                receivedMetrics = metrics
            }
            .store(in: &cancellables)
        
        output.error
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)
        
        // When
        loadTrigger.send(testAccountId)
        
        // Then
        XCTAssertNotNil(receivedMetrics)
        XCTAssertEqual(receivedMetrics?.totalValue, 10000)
        XCTAssertEqual(receivedMetrics?.totalReturn, 2000)
        XCTAssertEqual(receivedMetrics?.returnPercentage, 20)
        XCTAssertEqual(receivedMetrics?.numberOfInvestments, 2)
        XCTAssertNil(receivedError)
    }
    
    /// Tests investment selection handling
    /// Verifies Investment Tracking requirement for portfolio monitoring
    func testInvestmentSelection() {
        // Given
        let selectedInvestment = Investment(
            id: UUID(),
            accountId: testAccountId,
            symbol: "AAPL",
            name: "Apple Inc.",
            type: .stock,
            shares: 10,
            costBasis: 1500,
            currentPrice: 150
        )
        
        let selectionTrigger = PassthroughSubject<Investment, Never>()
        let input = InvestmentListViewModel.Input(
            loadPortfolioTrigger: Empty().eraseToAnyPublisher(),
            refreshTrigger: Empty().eraseToAnyPublisher(),
            investmentSelection: selectionTrigger.eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        var selectedInvestments: [Investment] = []
        
        output.investments
            .sink { investments in
                selectedInvestments = investments
            }
            .store(in: &cancellables)
        
        // When
        selectionTrigger.send(selectedInvestment)
        
        // Then
        XCTAssertEqual(selectedInvestments.count, 0) // Selection doesn't modify list
    }
}

// MARK: - Mock Investment Use Case

/// Mock implementation of InvestmentUseCase for testing
private final class MockInvestmentUseCase: InvestmentUseCase {
    var portfolioResult: Result<[Investment], Error>!
    var metricsResult: Result<PortfolioMetrics, Error>!
    let mockInvestmentUpdatePublisher = PassthroughSubject<Investment, Error>()
    
    override func getPortfolio(accountId: UUID) -> AnyPublisher<[Investment], Error> {
        return Future<[Investment], Error> { promise in
            promise(self.portfolioResult)
        }.eraseToAnyPublisher()
    }
    
    override func calculatePortfolioMetrics(accountId: UUID) -> AnyPublisher<PortfolioMetrics, Error> {
        return Future<PortfolioMetrics, Error> { promise in
            promise(self.metricsResult)
        }.eraseToAnyPublisher()
    }
}