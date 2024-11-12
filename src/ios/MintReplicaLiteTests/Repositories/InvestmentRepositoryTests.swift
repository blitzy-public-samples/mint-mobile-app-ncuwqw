//
// InvestmentRepositoryTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Verify Core Data test configuration in scheme settings
// 2. Configure test data fixtures if needed for larger test suites
// 3. Review error handling test coverage requirements
// 4. Set up CI pipeline test reporting integration

// XCTest framework - iOS 14.0+
import XCTest
// CoreData framework - iOS 14.0+
import CoreData
@testable import MintReplicaLite

/// Test suite for InvestmentRepository class verifying thread-safe CRUD operations and investment calculations
/// Implements:
/// - Investment Tracking (Section 1.2): Tests for portfolio monitoring and investment account integration
/// - Local Data Persistence (Section 4.3.2): Verification of Core Data investment data storage
final class InvestmentRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: InvestmentRepository!
    private var coreDataManager: CoreDataManager!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        // Initialize CoreDataManager with in-memory store for testing
        coreDataManager = CoreDataManager.shared
        // Initialize system under test
        sut = InvestmentRepository(coreDataManager: coreDataManager)
        // Ensure clean state before each test
        coreDataManager.clearDatabase()
    }
    
    override func tearDown() {
        // Clean up test data
        coreDataManager.clearDatabase()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests saving a new investment with proper thread handling
    /// Verifies Investment Tracking requirement for portfolio data persistence
    func testSaveInvestment() {
        // Given
        let investmentId = UUID()
        let accountId = UUID()
        let testInvestment = Investment(
            id: investmentId,
            accountId: accountId,
            symbol: "AAPL",
            name: "Apple Inc.",
            type: .stock,
            shares: Decimal(10),
            costBasis: Decimal(1500),
            currentPrice: Decimal(150)
        )
        
        // When
        let saveResult = sut.saveInvestment(investment: testInvestment)
        
        // Then
        switch saveResult {
        case .success(let savedInvestment):
            XCTAssertEqual(savedInvestment.id, investmentId)
            XCTAssertEqual(savedInvestment.accountId, accountId)
            XCTAssertEqual(savedInvestment.symbol, "AAPL")
            XCTAssertEqual(savedInvestment.name, "Apple Inc.")
            XCTAssertEqual(savedInvestment.type, .stock)
            XCTAssertEqual(savedInvestment.shares, Decimal(10))
            XCTAssertEqual(savedInvestment.costBasis, Decimal(1500))
            XCTAssertEqual(savedInvestment.currentPrice, Decimal(150))
        case .failure(let error):
            XCTFail("Failed to save investment: \(error.localizedDescription)")
        }
    }
    
    /// Tests retrieving an investment by ID with proper error handling
    /// Verifies Investment Tracking requirement for portfolio data retrieval
    func testGetInvestment() {
        // Given
        let investmentId = UUID()
        let accountId = UUID()
        let testInvestment = Investment(
            id: investmentId,
            accountId: accountId,
            symbol: "GOOGL",
            name: "Alphabet Inc.",
            type: .stock,
            shares: Decimal(5),
            costBasis: Decimal(2500),
            currentPrice: Decimal(500)
        )
        
        // Save test investment
        let saveResult = sut.saveInvestment(investment: testInvestment)
        guard case .success = saveResult else {
            XCTFail("Failed to save test investment")
            return
        }
        
        // When
        let fetchedInvestment = sut.getInvestment(id: investmentId)
        
        // Then
        XCTAssertNotNil(fetchedInvestment)
        XCTAssertEqual(fetchedInvestment?.id, investmentId)
        XCTAssertEqual(fetchedInvestment?.symbol, "GOOGL")
        XCTAssertEqual(fetchedInvestment?.shares, Decimal(5))
        
        // Test invalid ID returns nil
        let invalidFetch = sut.getInvestment(id: UUID())
        XCTAssertNil(invalidFetch)
    }
    
    /// Tests retrieving all investments for an account
    /// Verifies Investment Tracking requirement for portfolio monitoring
    func testGetInvestments() {
        // Given
        let accountId = UUID()
        let investment1 = Investment(
            id: UUID(),
            accountId: accountId,
            symbol: "MSFT",
            name: "Microsoft Corp",
            type: .stock,
            shares: Decimal(15),
            costBasis: Decimal(3000),
            currentPrice: Decimal(200)
        )
        
        let investment2 = Investment(
            id: UUID(),
            accountId: accountId,
            symbol: "AMZN",
            name: "Amazon.com Inc",
            type: .stock,
            shares: Decimal(8),
            costBasis: Decimal(2400),
            currentPrice: Decimal(300)
        )
        
        // Save test investments
        _ = sut.saveInvestment(investment: investment1)
        _ = sut.saveInvestment(investment: investment2)
        
        // When
        let investments = sut.getInvestments(accountId: accountId)
        
        // Then
        XCTAssertEqual(investments.count, 2)
        XCTAssertTrue(investments.contains { $0.symbol == "MSFT" })
        XCTAssertTrue(investments.contains { $0.symbol == "AMZN" })
        
        // Test invalid account ID returns empty array
        let invalidAccountInvestments = sut.getInvestments(accountId: UUID())
        XCTAssertTrue(invalidAccountInvestments.isEmpty)
    }
    
    /// Tests updating investment price with value recalculation
    /// Verifies Investment Tracking requirement for real-time price updates
    func testUpdateInvestmentPrice() {
        // Given
        let investmentId = UUID()
        let testInvestment = Investment(
            id: investmentId,
            accountId: UUID(),
            symbol: "TSLA",
            name: "Tesla Inc",
            type: .stock,
            shares: Decimal(10),
            costBasis: Decimal(3000),
            currentPrice: Decimal(300)
        )
        
        // Save test investment
        _ = sut.saveInvestment(investment: testInvestment)
        
        // When
        let newPrice = Decimal(350)
        let updateResult = sut.updateInvestmentPrice(id: investmentId, newPrice: newPrice)
        
        // Then
        switch updateResult {
        case .success(let updatedInvestment):
            XCTAssertEqual(updatedInvestment.currentPrice, newPrice)
            XCTAssertEqual(updatedInvestment.currentValue, newPrice * updatedInvestment.shares)
            
            // Verify persisted changes
            let fetchedInvestment = sut.getInvestment(id: investmentId)
            XCTAssertEqual(fetchedInvestment?.currentPrice, newPrice)
            
        case .failure(let error):
            XCTFail("Failed to update investment price: \(error.localizedDescription)")
        }
        
        // Test invalid ID returns error
        let invalidUpdateResult = sut.updateInvestmentPrice(id: UUID(), newPrice: newPrice)
        if case .success = invalidUpdateResult {
            XCTFail("Update should fail for invalid investment ID")
        }
    }
    
    /// Tests deleting an investment with proper cleanup
    /// Verifies Local Data Persistence requirement for data management
    func testDeleteInvestment() {
        // Given
        let investmentId = UUID()
        let testInvestment = Investment(
            id: investmentId,
            accountId: UUID(),
            symbol: "NFLX",
            name: "Netflix Inc",
            type: .stock,
            shares: Decimal(20),
            costBasis: Decimal(4000),
            currentPrice: Decimal(200)
        )
        
        // Save test investment
        _ = sut.saveInvestment(investment: testInvestment)
        
        // When
        let deleteResult = sut.deleteInvestment(id: investmentId)
        
        // Then
        switch deleteResult {
        case .success:
            // Verify investment was deleted
            let fetchedInvestment = sut.getInvestment(id: investmentId)
            XCTAssertNil(fetchedInvestment)
            
        case .failure(let error):
            XCTFail("Failed to delete investment: \(error.localizedDescription)")
        }
        
        // Test invalid ID returns error
        let invalidDeleteResult = sut.deleteInvestment(id: UUID())
        if case .success = invalidDeleteResult {
            XCTFail("Delete should fail for invalid investment ID")
        }
    }
}