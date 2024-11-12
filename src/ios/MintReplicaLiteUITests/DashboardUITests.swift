//
// DashboardUITests.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify test coverage on different iOS device sizes (iPhone SE to iPad Pro)
// 2. Test accessibility features with VoiceOver enabled
// 3. Validate test stability on CI/CD pipeline
// 4. Review test performance with large datasets
// 5. Test offline mode behavior

// Third-party Dependencies:
// - XCTest (iOS 14.0+)

import XCTest

/// UI test suite for Dashboard screen functionality
/// Requirements addressed:
/// - Dashboard Layout (5.1 User Interface Design/5.1.2 Dashboard Layout): Verify comprehensive dashboard view
/// - Account Management (1.2 Scope/Account Management): Verify real-time balance updates
/// - Financial Tracking (1.2 Scope/Financial Tracking): Verify transaction display and categorization
final class DashboardUITests: XCTestCase {
    
    // MARK: - Properties
    
    private var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Ensure we're on the dashboard screen
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            tabBar.buttons["Dashboard"].tap()
        }
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Test Cases
    
    /// Tests initial loading of dashboard components
    /// Requirement: Dashboard Layout (5.1.2)
    func testDashboardInitialLoad() throws {
        // Verify scroll view exists and is accessible
        let scrollView = app.scrollViews["Dashboard content"]
        XCTAssertTrue(scrollView.exists, "Dashboard scroll view should exist")
        XCTAssertTrue(scrollView.isEnabled, "Dashboard scroll view should be enabled")
        
        // Verify container stack view exists
        let containerStack = scrollView.otherElements["containerStackView"]
        XCTAssertTrue(containerStack.exists, "Container stack view should exist")
        
        // Verify account summary section
        let accountSummary = scrollView.otherElements["Account summary"]
        XCTAssertTrue(accountSummary.exists, "Account summary view should exist")
        XCTAssertTrue(accountSummary.isHittable, "Account summary view should be visible")
        
        // Verify budget summary section
        let budgetSummary = scrollView.otherElements["Budget summary"]
        XCTAssertTrue(budgetSummary.exists, "Budget summary view should exist")
        XCTAssertTrue(budgetSummary.isHittable, "Budget summary view should be visible")
        
        // Verify net worth display
        let netWorthLabel = scrollView.staticTexts.matching(identifier: "Net Worth").firstMatch
        XCTAssertTrue(netWorthLabel.exists, "Net worth label should exist")
        XCTAssertFalse(netWorthLabel.label.isEmpty, "Net worth should display a value")
    }
    
    /// Tests pull-to-refresh functionality
    /// Requirement: Account Management (1.2)
    func testDashboardPullToRefresh() throws {
        let scrollView = app.scrollViews["Dashboard content"]
        XCTAssertTrue(scrollView.exists, "Dashboard scroll view should exist")
        
        // Verify refresh control exists
        let refreshControl = scrollView.otherElements["Refresh dashboard"]
        XCTAssertTrue(refreshControl.exists, "Refresh control should exist")
        
        // Perform pull-to-refresh gesture
        scrollView.swipeDown()
        
        // Verify refresh control is visible and animating
        XCTAssertTrue(refreshControl.isHittable, "Refresh control should be visible during refresh")
        
        // Wait for refresh to complete (max 5 seconds)
        let refreshComplete = NSPredicate(format: "exists == false")
        let expectation = expectation(for: refreshComplete, evaluatedWith: refreshControl, handler: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(result, .completed, "Refresh should complete within timeout")
    }
    
    /// Tests account summary card interactions
    /// Requirements: Account Management (1.2), Dashboard Layout (5.1.2)
    func testAccountSummaryInteraction() throws {
        let accountSummary = app.scrollViews["Dashboard content"].otherElements["Account summary"]
        XCTAssertTrue(accountSummary.exists, "Account summary view should exist")
        
        // Verify account cards exist
        let accountCards = accountSummary.cells
        XCTAssertTrue(accountCards.count > 0, "At least one account card should exist")
        
        // Tap first account card
        let firstCard = accountCards.firstMatch
        XCTAssertTrue(firstCard.exists, "First account card should exist")
        firstCard.tap()
        
        // Verify navigation to account details
        let accountDetailsTitle = app.navigationBars["Account Details"].firstMatch
        XCTAssertTrue(accountDetailsTitle.waitForExistence(timeout: 2.0), "Should navigate to account details")
        
        // Verify account details content
        let balanceLabel = app.staticTexts.matching(identifier: "Account Balance").firstMatch
        XCTAssertTrue(balanceLabel.exists, "Balance label should exist in account details")
        XCTAssertFalse(balanceLabel.label.isEmpty, "Balance should display a value")
    }
    
    /// Tests budget summary section interactions
    /// Requirements: Financial Tracking (1.2), Dashboard Layout (5.1.2)
    func testBudgetSummaryInteraction() throws {
        let budgetSummary = app.scrollViews["Dashboard content"].otherElements["Budget summary"]
        XCTAssertTrue(budgetSummary.exists, "Budget summary view should exist")
        
        // Verify budget progress indicators
        let progressBars = budgetSummary.progressIndicators
        XCTAssertTrue(progressBars.count > 0, "Budget progress indicators should exist")
        
        // Tap budget summary section
        budgetSummary.tap()
        
        // Verify navigation to budget details
        let budgetDetailsTitle = app.navigationBars["Budget Details"].firstMatch
        XCTAssertTrue(budgetDetailsTitle.waitForExistence(timeout: 2.0), "Should navigate to budget details")
        
        // Verify budget details content
        let categoryLabels = app.staticTexts.matching(identifier: "Budget Category")
        XCTAssertTrue(categoryLabels.count > 0, "Budget categories should exist in details view")
    }
    
    /// Tests scrolling through recent transactions
    /// Requirement: Financial Tracking (1.2)
    func testRecentTransactionsScroll() throws {
        let scrollView = app.scrollViews["Dashboard content"]
        
        // Scroll to recent transactions section
        let recentTransactions = scrollView.otherElements["Recent Transactions"]
        XCTAssertTrue(recentTransactions.exists, "Recent transactions section should exist")
        
        // Scroll to make transactions visible
        recentTransactions.swipeUp()
        
        // Verify transaction cells
        let transactionCells = recentTransactions.cells
        XCTAssertTrue(transactionCells.count > 0, "Transaction cells should exist")
        
        // Verify first transaction cell content
        let firstTransaction = transactionCells.firstMatch
        XCTAssertTrue(firstTransaction.exists, "First transaction cell should exist")
        
        // Verify transaction amount
        let amountLabel = firstTransaction.staticTexts.matching(identifier: "Transaction Amount").firstMatch
        XCTAssertTrue(amountLabel.exists, "Transaction amount should exist")
        XCTAssertFalse(amountLabel.label.isEmpty, "Transaction amount should display a value")
        
        // Verify transaction date
        let dateLabel = firstTransaction.staticTexts.matching(identifier: "Transaction Date").firstMatch
        XCTAssertTrue(dateLabel.exists, "Transaction date should exist")
        XCTAssertFalse(dateLabel.label.isEmpty, "Transaction date should display a value")
        
        // Verify transaction category
        let categoryLabel = firstTransaction.staticTexts.matching(identifier: "Transaction Category").firstMatch
        XCTAssertTrue(categoryLabel.exists, "Transaction category should exist")
        XCTAssertFalse(categoryLabel.label.isEmpty, "Transaction category should display a value")
    }
}