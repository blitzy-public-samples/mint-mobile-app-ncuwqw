//
// AccountsUITests.swift
// MintReplicaLiteUITests
//
// HUMAN TASKS:
// 1. Configure test environment with sample test accounts data
// 2. Verify network conditions simulation for refresh testing
// 3. Review accessibility testing requirements
// 4. Set up CI/CD test execution environment

// XCTest framework - iOS 14.0+
import XCTest

/// UI test suite for verifying account management functionality
/// Implements:
/// - Account Management (Section 1.2): Testing financial account aggregation and real-time updates
/// - UI Implementation (Section 5.1.2): Validation of account list view against iOS HIG
final class AccountsUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // Configure launch arguments for UI testing environment
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["UITEST_MODE"] = "1"
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }
    
    /// Tests the display of accounts list view and its components
    /// Verifies Account Management requirement for account list display
    func testAccountListDisplay() throws {
        // Navigate to accounts tab
        let tabBar = app.tabBars.firstMatch
        let accountsTab = tabBar.buttons["Accounts"]
        XCTAssertTrue(accountsTab.exists)
        accountsTab.tap()
        
        // Verify table view exists
        let accountsTableView = app.tables.firstMatch
        XCTAssertTrue(accountsTableView.exists)
        
        // Verify account cells
        let accountCells = accountsTableView.cells.matching(identifier: "AccountCell")
        XCTAssertTrue(accountCells.count > 0, "Account list should not be empty")
        
        // Verify first account cell elements
        let firstCell = accountCells.element(boundBy: 0)
        XCTAssertTrue(firstCell.exists)
        
        // Verify account name label
        let nameLabel = firstCell.staticTexts.firstMatch
        XCTAssertTrue(nameLabel.exists)
        XCTAssertFalse(nameLabel.label.isEmpty)
        
        // Verify account balance label with currency format
        let balanceLabel = firstCell.staticTexts.element(matching: NSPredicate(format: "label CONTAINS '$'"))
        XCTAssertTrue(balanceLabel.exists)
        
        // Verify account type indicator
        let typeIndicator = firstCell.images["AccountTypeIcon"]
        XCTAssertTrue(typeIndicator.exists)
        
        // Verify loading and error views are not visible initially
        XCTAssertFalse(app.otherElements["LoadingView"].exists)
        XCTAssertFalse(app.otherElements["ErrorView"].exists)
    }
    
    /// Tests pull-to-refresh functionality in accounts list
    /// Verifies Account Management requirement for real-time balance updates
    func testAccountRefresh() throws {
        // Navigate to accounts tab
        app.tabBars.buttons["Accounts"].tap()
        
        let accountsTableView = app.tables.firstMatch
        XCTAssertTrue(accountsTableView.exists)
        
        // Verify refresh control exists
        let refreshControl = accountsTableView.otherElements["RefreshControl"]
        XCTAssertTrue(refreshControl.exists)
        
        // Perform pull-to-refresh gesture
        accountsTableView.swipeDown()
        
        // Verify loading view appears during refresh
        let loadingView = app.otherElements["LoadingView"]
        XCTAssertTrue(loadingView.waitForExistence(timeout: 2))
        
        // Wait for refresh to complete
        XCTAssertTrue(loadingView.waitForNonExistence(timeout: 5))
        
        // Verify accounts are still displayed after refresh
        let accountCells = accountsTableView.cells.matching(identifier: "AccountCell")
        XCTAssertTrue(accountCells.count > 0)
    }
    
    /// Tests account detail view navigation and display
    /// Verifies UI Implementation requirement for account details presentation
    func testAccountDetails() throws {
        // Navigate to accounts tab
        app.tabBars.buttons["Accounts"].tap()
        
        let accountsTableView = app.tables.firstMatch
        let firstCell = accountsTableView.cells.element(boundBy: 0)
        
        // Store initial account info for comparison
        let initialName = firstCell.staticTexts.element(boundBy: 0).label
        let initialBalance = firstCell.staticTexts.element(matching: NSPredicate(format: "label CONTAINS '$'")).label
        
        // Navigate to detail view
        firstCell.tap()
        
        // Verify detail view appears
        let detailView = app.navigationBars[initialName]
        XCTAssertTrue(detailView.exists)
        
        // Verify account details
        let detailNameLabel = app.staticTexts[initialName]
        XCTAssertTrue(detailNameLabel.exists)
        
        let detailBalanceLabel = app.staticTexts[initialBalance]
        XCTAssertTrue(detailBalanceLabel.exists)
        
        // Verify account type indicator in detail view
        let detailTypeIndicator = app.images["DetailAccountTypeIcon"]
        XCTAssertTrue(detailTypeIndicator.exists)
        
        // Verify account status indicator
        let statusIndicator = app.otherElements["AccountStatusIndicator"]
        XCTAssertTrue(statusIndicator.exists)
    }
}