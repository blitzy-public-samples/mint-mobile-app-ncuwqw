//
// InvestmentUseCaseTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Configure test environment with appropriate test database credentials
// 2. Review test coverage requirements with QA team
// 3. Set up performance testing baseline metrics
// 4. Configure CI pipeline test timeouts for async operations

// XCTest framework - iOS 14.0+
import XCTest
// Combine framework - iOS 14.0+
import Combine
@testable import MintReplicaLite

/// Mock repository for testing InvestmentUseCase
final class MockInvestmentRepository {
    private var investments: [UUID: Investment] = [:]
    var mockError: Error?
    let updatePublisher = PassthroughSubject<Investment, Error>()
    
    func getInvestment(id: UUID) -> AnyPublisher<Investment?, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(investments[id])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func getInvestments(accountId: UUID) -> AnyPublisher<[Investment], Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        let filtered = investments.values.filter { $0.accountId == accountId }
        return Just(Array(filtered))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func saveInvestment(investment: Investment) -> AnyPublisher<Investment, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        investments[investment.id] = investment
        updatePublisher.send(investment)
        return Just(investment)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func deleteInvestment(id: UUID) -> AnyPublisher<Void, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        investments.removeValue(forKey: id)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

/// Test suite for InvestmentUseCase
/// Implements Investment Tracking requirement (Section 1.2) testing
final class InvestmentUseCaseTests: XCTestCase {
    private var sut: InvestmentUseCase!
    private var mockRepository: MockInvestmentRepository!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockInvestmentRepository()
        sut = InvestmentUseCase(repository: mockRepository)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    /// Tests portfolio retrieval functionality
    /// Verifies Investment Tracking requirement for portfolio monitoring
    func testGetPortfolio() {
        // Given
        let accountId = UUID()
        let investment1 = Investment(id: UUID(), accountId: accountId, symbol: "AAPL", name: "Apple Inc.", type: .stock, shares: 10, costBasis: 1500.00, currentPrice: 150.00)
        let investment2 = Investment(id: UUID(), accountId: accountId, symbol: "GOOGL", name: "Alphabet Inc.", type: .stock, shares: 5, costBasis: 2500.00, currentPrice: 500.00)
        
        let expectation = expectation(description: "Get portfolio")
        var receivedInvestments: [Investment]?
        
        // When
        mockRepository.saveInvestment(investment: investment1).sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
        mockRepository.saveInvestment(investment: investment2).sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
        
        sut.getPortfolio(accountId: accountId)
            .sink { completion in
                if case .failure = completion {
                    XCTFail("Portfolio retrieval failed")
                }
            } receiveValue: { investments in
                receivedInvestments = investments
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedInvestments?.count, 2)
        XCTAssertTrue(receivedInvestments?.contains { $0.symbol == "AAPL" } ?? false)
        XCTAssertTrue(receivedInvestments?.contains { $0.symbol == "GOOGL" } ?? false)
    }
    
    /// Tests adding new investment
    /// Verifies Investment Tracking requirement for portfolio updates
    func testAddInvestment() {
        // Given
        let investment = Investment(id: UUID(), accountId: UUID(), symbol: "MSFT", name: "Microsoft Corp", type: .stock, shares: 15, costBasis: 3000.00, currentPrice: 200.00)
        let expectation = expectation(description: "Add investment")
        var receivedInvestment: Investment?
        
        // When
        sut.addInvestment(investment: investment)
            .sink { completion in
                if case .failure = completion {
                    XCTFail("Investment addition failed")
                }
            } receiveValue: { savedInvestment in
                receivedInvestment = savedInvestment
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedInvestment?.symbol, "MSFT")
        XCTAssertEqual(receivedInvestment?.shares, 15)
        XCTAssertEqual(receivedInvestment?.costBasis, 3000.00)
    }
    
    /// Tests updating investment price
    /// Verifies Investment Tracking requirement for real-time price updates
    func testUpdateInvestmentPrice() {
        // Given
        let investment = Investment(id: UUID(), accountId: UUID(), symbol: "TSLA", name: "Tesla Inc", type: .stock, shares: 5, costBasis: 2000.00, currentPrice: 400.00)
        let newPrice: Decimal = 450.00
        let expectation = expectation(description: "Update investment price")
        var updatedInvestment: Investment?
        
        // When
        mockRepository.saveInvestment(investment: investment).sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
        
        sut.updateInvestmentPrice(investmentId: investment.id, newPrice: newPrice)
            .sink { completion in
                if case .failure = completion {
                    XCTFail("Price update failed")
                }
            } receiveValue: { investment in
                updatedInvestment = investment
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(updatedInvestment?.currentPrice, newPrice)
        XCTAssertEqual(updatedInvestment?.currentValue, newPrice * investment.shares)
    }
    
    /// Tests updating investment shares
    /// Verifies Investment Tracking requirement for portfolio updates
    func testUpdateInvestmentShares() {
        // Given
        let investment = Investment(id: UUID(), accountId: UUID(), symbol: "AMZN", name: "Amazon.com Inc", type: .stock, shares: 10, costBasis: 3000.00, currentPrice: 300.00)
        let newShares: Decimal = 15
        let newCostBasis: Decimal = 4500.00
        let expectation = expectation(description: "Update investment shares")
        var updatedInvestment: Investment?
        
        // When
        mockRepository.saveInvestment(investment: investment).sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
        
        sut.updateInvestmentShares(investmentId: investment.id, newShares: newShares, newCostBasis: newCostBasis)
            .sink { completion in
                if case .failure = completion {
                    XCTFail("Shares update failed")
                }
            } receiveValue: { investment in
                updatedInvestment = investment
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(updatedInvestment?.shares, newShares)
        XCTAssertEqual(updatedInvestment?.costBasis, newCostBasis)
    }
    
    /// Tests removing investment
    /// Verifies Investment Tracking requirement for portfolio management
    func testRemoveInvestment() {
        // Given
        let investment = Investment(id: UUID(), accountId: UUID(), symbol: "FB", name: "Meta Platforms Inc", type: .stock, shares: 20, costBasis: 4000.00, currentPrice: 200.00)
        let expectation = expectation(description: "Remove investment")
        
        // When
        mockRepository.saveInvestment(investment: investment).sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
        
        sut.removeInvestment(investmentId: investment.id)
            .sink { completion in
                if case .failure = completion {
                    XCTFail("Investment removal failed")
                }
            } receiveValue: { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        mockRepository.getInvestment(id: investment.id)
            .sink { _ in } receiveValue: { retrievedInvestment in
                XCTAssertNil(retrievedInvestment)
            }
            .store(in: &cancellables)
    }
    
    /// Tests portfolio metrics calculation
    /// Verifies Investment Tracking requirement for performance metrics
    func testCalculatePortfolioMetrics() {
        // Given
        let accountId = UUID()
        let investment1 = Investment(id: UUID(), accountId: accountId, symbol: "VTI", name: "Vanguard Total Stock", type: .etf, shares: 50, costBasis: 7500.00, currentPrice: 160.00)
        let investment2 = Investment(id: UUID(), accountId: accountId, symbol: "BND", name: "Vanguard Total Bond", type: .etf, shares: 100, costBasis: 8000.00, currentPrice: 85.00)
        let expectation = expectation(description: "Calculate portfolio metrics")
        var metrics: PortfolioMetrics?
        
        // When
        mockRepository.saveInvestment(investment: investment1).sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
        mockRepository.saveInvestment(investment: investment2).sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
        
        sut.calculatePortfolioMetrics(accountId: accountId)
            .sink { completion in
                if case .failure = completion {
                    XCTFail("Metrics calculation failed")
                }
            } receiveValue: { calculatedMetrics in
                metrics = calculatedMetrics
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(metrics?.totalValue, 16500.00) // (50 * 160) + (100 * 85)
        XCTAssertEqual(metrics?.totalReturn, 1000.00) // 16500 - (7500 + 8000)
        XCTAssertEqual(metrics?.returnPercentage, 6.45) // (1000 / 15500) * 100
        XCTAssertEqual(metrics?.numberOfInvestments, 2)
    }
    
    /// Tests error handling for invalid price update
    func testUpdateInvestmentPriceWithInvalidPrice() {
        // Given
        let investment = Investment(id: UUID(), accountId: UUID(), symbol: "NFLX", name: "Netflix Inc", type: .stock, shares: 10, costBasis: 3000.00, currentPrice: 300.00)
        let expectation = expectation(description: "Invalid price update")
        
        // When
        mockRepository.saveInvestment(investment: investment).sink { _ in } receiveValue: { _ in }.store(in: &cancellables)
        
        sut.updateInvestmentPrice(investmentId: investment.id, newPrice: -100)
            .sink { completion in
                if case .failure = completion {
                    expectation.fulfill()
                }
            } receiveValue: { _ in
                XCTFail("Should not succeed with negative price")
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0)
    }
}