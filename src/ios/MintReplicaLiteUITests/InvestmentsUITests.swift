//
// InvestmentsUITests.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify test device has sufficient test data configured
// 2. Ensure test device has network connectivity for refresh tests
// 3. Configure test device with empty state test account
// 4. Review and update test timeout values if needed based on device performance

// XCTest framework - iOS 14.0+
import XCTest

/// UI test suite for testing the investments feature functionality
/// Implements:
/// - Investment Tracking (1.2): Testing basic portfolio monitoring and investment account integration
/// - UI Implementation (5.1.6): Validating investment portfolio interface following iOS HIG
final class InvestmentsUITests: XCTestCase {
    
    // MARK: - Properties
    
    private var app: XCUIApplication!
    
    // MARK: - Setup/Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Navigate to investments tab
        app.tabBars.buttons["Investments"].tap()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Test Cases
    
    /// Tests the display of investment portfolio list and its components
    /// Validates Investment Tracking requirement (1.2) for portfolio monitoring
    func testInvestmentListDisplay() throws {
        // Verify investments tab is selected
        let investmentsTab = app.tabBars.buttons["Investments"]
        XCTAssertTrue(investmentsTab.isSelected, "Investments tab should be selected")
        
        // Verify table view exists
        let tableView = app.tables.element
        XCTAssertTrue(tableView.exists, "Investment list table view should exist")
        
        // Verify investment cells are present
        let cells = app.tables.cells
        XCTAssertGreaterThan(cells.count, 0, "Investment list should contain cells")
        
        // Verify first cell elements
        let firstCell = cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.staticTexts["symbolLabel"].exists, "Investment symbol should be visible")
        XCTAssertTrue(firstCell.staticTexts["nameLabel"].exists, "Investment name should be visible")
        XCTAssertTrue(firstCell.staticTexts["valueLabel"].exists, "Investment value should be visible")
        XCTAssertTrue(firstCell.staticTexts["returnLabel"].exists, "Investment return should be visible")
    }
    
    /// Tests the selection of an investment item and navigation to detail view
    /// Validates UI Implementation requirement (5.1.6) for investment interface
    func testInvestmentSelection() throws {
        // Get first investment cell
        let firstCell = app.tables.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.exists, "First investment cell should exist")
        
        // Store investment name for verification
        let investmentName = firstCell.staticTexts["nameLabel"].label
        
        // Tap on cell
        firstCell.tap()
        
        // Verify navigation to detail view
        let navigationBar = app.navigationBars[investmentName]
        XCTAssertTrue(navigationBar.exists, "Detail view navigation bar should show investment name")
        
        // Verify detail view elements
        XCTAssertTrue(app.staticTexts["currentValueLabel"].exists, "Current value should be visible")
        XCTAssertTrue(app.staticTexts["returnLabel"].exists, "Return information should be visible")
        XCTAssertTrue(app.staticTexts["lastUpdatedLabel"].exists, "Last updated timestamp should be visible")
    }
    
    /// Tests the pull-to-refresh functionality of the investment list
    /// Validates Investment Tracking requirement (1.2) for account integration
    func testInvestmentListRefresh() throws {
        let tableView = app.tables.element
        XCTAssertTrue(tableView.exists, "Table view should exist")
        
        // Perform pull-to-refresh gesture
        tableView.swipeDown()
        
        // Verify refresh control is visible
        let refreshControl = tableView.otherElements["RefreshControl"]
        XCTAssertTrue(refreshControl.exists, "Refresh control should be visible during refresh")
        
        // Wait for refresh to complete (max 5 seconds)
        let refreshComplete = NSPredicate(format: "exists == false")
        let expectation = expectation(for: refreshComplete, evaluatedWith: refreshControl, handler: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        
        XCTAssertEqual(result, .completed, "Refresh should complete within timeout period")
    }
    
    /// Tests the empty state display when no investments exist
    /// Validates UI Implementation requirement (5.1.6) for empty state handling
    func testEmptyStateDisplay() throws {
        // Note: This test requires a test account configured with no investments
        
        // Verify empty state view
        let emptyStateLabel = app.staticTexts["emptyStateLabel"]
        XCTAssertTrue(emptyStateLabel.exists, "Empty state label should be visible")
        
        // Verify empty state message
        XCTAssertEqual(
            emptyStateLabel.label,
            "No investments found",
            "Empty state should show correct message"
        )
        
        // Verify no cells are present
        let cells = app.tables.cells
        XCTAssertEqual(cells.count, 0, "Investment list should have no cells")
        
        // Verify add investment button is present
        let addButton = app.buttons["addInvestmentButton"]
        XCTAssertTrue(addButton.exists, "Add investment button should be visible in empty state")
        XCTAssertTrue(addButton.isEnabled, "Add investment button should be enabled")
    }
}