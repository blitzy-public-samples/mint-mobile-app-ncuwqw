//
// InvestmentsUITests.swift
// MintReplicaLiteUITests
//
// UI test suite for investment portfolio functionality
// XCTest framework version: iOS 14.0+
//

// HUMAN TASKS:
// 1. Ensure test data is properly seeded in the test environment
// 2. Configure test environment variables in scheme settings
// 3. Verify simulator has required permissions enabled
// 4. Set up mock financial institution responses for testing

import XCTest

class InvestmentsUITests: XCTestCase {
    
    // MARK: - Properties
    
    private var app: XCUIApplication!
    private var investmentsTab: XCUIElement!
    private var investmentsList: XCUIElement!
    private var syncButton: XCUIElement!
    private var refreshControl: XCUIElement!
    private var firstInvestmentCell: XCUIElement!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Initialize application instance
        app = XCUIApplication()
        
        // Configure test environment
        app.launchArguments += ["--uitesting"]
        app.launchEnvironment["IS_UI_TESTING"] = "1"
        
        // Launch the application
        app.launch()
        
        // Initialize UI element references
        // Requirement: 1.2 Scope/Investment Tracking - Basic portfolio monitoring
        investmentsTab = app.tabBars.buttons["Investments"]
        investmentsList = app.tables["InvestmentsList"]
        syncButton = app.buttons["SyncInvestments"]
        refreshControl = investmentsList.otherElements["RefreshControl"]
        firstInvestmentCell = investmentsList.cells.element(boundBy: 0)
        
        // Wait for initial app load
        XCTAssert(investmentsTab.waitForExistence(timeout: 5))
    }
    
    override func tearDown() {
        // Clean up test environment
        app.terminate()
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testInvestmentListDisplay() {
        // Requirement: 1.2 Scope/Investment Tracking - Basic portfolio monitoring
        // Test investment portfolio list display and content
        
        // Navigate to investments tab
        investmentsTab.tap()
        
        // Verify investments list exists
        XCTAssertTrue(investmentsList.exists)
        
        // Verify at least one investment account is displayed
        XCTAssertTrue(firstInvestmentCell.exists)
        
        // Verify investment cell contains required elements
        let accountName = firstInvestmentCell.staticTexts["AccountName"]
        let balance = firstInvestmentCell.staticTexts["Balance"]
        let performance = firstInvestmentCell.staticTexts["Performance"]
        
        XCTAssertTrue(accountName.exists)
        XCTAssertTrue(balance.exists)
        XCTAssertTrue(performance.exists)
        
        // Verify content format
        XCTAssertFalse(accountName.label.isEmpty)
        XCTAssertTrue(balance.label.contains("$"))
        XCTAssertTrue(performance.label.contains("%"))
    }
    
    func testInvestmentRefresh() {
        // Requirement: 1.2 Scope/Investment Tracking - Basic portfolio monitoring
        // Test pull-to-refresh functionality for investment data
        
        // Navigate to investments tab
        investmentsTab.tap()
        
        // Store initial values for comparison
        let initialBalance = firstInvestmentCell.staticTexts["Balance"].label
        
        // Trigger pull-to-refresh
        investmentsList.swipeDown()
        
        // Verify refresh control is visible
        XCTAssertTrue(refreshControl.exists)
        
        // Wait for refresh to complete (max 10 seconds)
        let refreshComplete = NSPredicate(format: "exists == false")
        expectation(for: refreshComplete, evaluatedWith: refreshControl, handler: nil)
        waitForExpectations(timeout: 10)
        
        // Verify data was updated
        let updatedBalance = firstInvestmentCell.staticTexts["Balance"].label
        XCTAssertNotEqual(initialBalance, updatedBalance)
    }
    
    func testInvestmentDetails() {
        // Requirement: 1.2 Scope/Investment Tracking - Basic portfolio monitoring
        // Test navigation to and content of investment detail view
        
        // Navigate to investments tab
        investmentsTab.tap()
        
        // Tap first investment cell
        firstInvestmentCell.tap()
        
        // Verify navigation to detail view
        let detailView = app.otherElements["InvestmentDetailView"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5))
        
        // Verify required detail sections exist
        let accountDetails = detailView.otherElements["AccountDetailsSection"]
        let performanceChart = detailView.otherElements["PerformanceChart"]
        let holdingsList = detailView.tables["HoldingsList"]
        let transactionHistory = detailView.tables["TransactionHistory"]
        
        XCTAssertTrue(accountDetails.exists)
        XCTAssertTrue(performanceChart.exists)
        XCTAssertTrue(holdingsList.exists)
        XCTAssertTrue(transactionHistory.exists)
        
        // Verify account details content
        let accountName = accountDetails.staticTexts["AccountName"]
        let accountType = accountDetails.staticTexts["AccountType"]
        let accountBalance = accountDetails.staticTexts["AccountBalance"]
        
        XCTAssertFalse(accountName.label.isEmpty)
        XCTAssertFalse(accountType.label.isEmpty)
        XCTAssertTrue(accountBalance.label.contains("$"))
    }
    
    func testInvestmentSync() {
        // Requirement: 1.2 Scope/Investment Tracking - Basic portfolio monitoring
        // Test manual sync functionality for investment data
        
        // Navigate to investments tab
        investmentsTab.tap()
        
        // Store initial sync timestamp
        let initialSyncTime = app.staticTexts["LastSyncTime"].label
        
        // Trigger manual sync
        syncButton.tap()
        
        // Verify sync progress indicator
        let syncIndicator = app.activityIndicators["SyncProgress"]
        XCTAssertTrue(syncIndicator.exists)
        
        // Wait for sync to complete (max 15 seconds)
        let syncComplete = NSPredicate(format: "exists == false")
        expectation(for: syncComplete, evaluatedWith: syncIndicator, handler: nil)
        waitForExpectations(timeout: 15)
        
        // Verify sync timestamp was updated
        let updatedSyncTime = app.staticTexts["LastSyncTime"].label
        XCTAssertNotEqual(initialSyncTime, updatedSyncTime)
        
        // Verify investment data was updated
        let updatedBalance = firstInvestmentCell.staticTexts["Balance"].label
        XCTAssertFalse(updatedBalance.isEmpty)
    }
}