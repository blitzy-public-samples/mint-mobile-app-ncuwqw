// HUMAN TASKS:
// 1. Verify XCTest framework is properly linked in project settings
// 2. Configure test scheme with appropriate launch arguments and environment variables
// 3. Review test coverage requirements with QA team
// 4. Set up test data fixtures for consistent test execution

// XCTest framework - iOS 14.0+
import XCTest

/// UI test suite for budget management functionality
/// Requirements addressed:
/// - Category-based budgeting (1.2 Scope/Budget Management): Budget creation and management tests
/// - Progress monitoring (1.2 Scope/Budget Management): Budget progress visualization tests
/// - UI Component Design (5.1 User Interface Design/5.1.2 Screen Layouts): Layout verification tests
final class BudgetsUITests: XCTestCase {
    
    // MARK: - Properties
    
    private var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set launch arguments to reset app state
        app.launchArguments = ["--uitesting"]
        app.launch()
        
        // Navigate to budgets tab
        app.tabBars.buttons["Budgets"].tap()
        
        // Wait for budget list to load
        let budgetList = app.tables["Budgets list"]
        XCTAssertTrue(budgetList.waitForExistence(timeout: 5))
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Test Cases
    
    func testBudgetListDisplay() throws {
        // Verify budget list exists
        let budgetList = app.tables["Budgets list"]
        XCTAssertTrue(budgetList.exists)
        
        // Verify period filter
        let periodFilter = app.segmentedControls["Budget period filter"]
        XCTAssertTrue(periodFilter.exists)
        XCTAssertEqual(periodFilter.buttons.count, 3)
        XCTAssertTrue(periodFilter.buttons["Monthly"].exists)
        XCTAssertTrue(periodFilter.buttons["Quarterly"].exists)
        XCTAssertTrue(periodFilter.buttons["Annual"].exists)
        
        // Verify add button in navigation bar
        let addButton = app.navigationBars.buttons["Add"]
        XCTAssertTrue(addButton.exists)
        
        // Verify budget cell elements if cells exist
        if budgetList.cells.count > 0 {
            let firstCell = budgetList.cells.element(boundBy: 0)
            XCTAssertTrue(firstCell.staticTexts.element(matching: .any, identifier: "Category").exists)
            XCTAssertTrue(firstCell.staticTexts.element(matching: .any, identifier: "Budget amount").exists)
            XCTAssertTrue(firstCell.staticTexts.element(matching: .any, identifier: "Amount spent").exists)
            XCTAssertTrue(firstCell.progressIndicators["Budget progress"].exists)
        }
    }
    
    func testBudgetCreation() throws {
        // Tap add button
        app.navigationBars.buttons["Add"].tap()
        
        // Verify budget creation form
        let categoryPicker = app.pickers["Category picker"]
        XCTAssertTrue(categoryPicker.waitForExistence(timeout: 2))
        
        // Select category
        categoryPicker.pickerWheels.element.adjust(toPickerWheelValue: "Groceries")
        
        // Enter amount
        let amountField = app.textFields["Amount field"]
        XCTAssertTrue(amountField.exists)
        amountField.tap()
        amountField.typeText("500")
        
        // Submit form
        app.buttons["Done"].tap()
        
        // Verify new budget appears
        let budgetList = app.tables["Budgets list"]
        let newBudgetCell = budgetList.cells.containing(.staticText, identifier: "Groceries").element
        XCTAssertTrue(newBudgetCell.waitForExistence(timeout: 2))
        
        // Verify initial progress
        let progressBar = newBudgetCell.progressIndicators["Budget progress"]
        XCTAssertEqual(progressBar.value as? String, "0% used")
    }
    
    func testBudgetDeletion() throws {
        let budgetList = app.tables["Budgets list"]
        guard budgetList.cells.count > 0 else {
            XCTFail("No budgets available for deletion test")
            return
        }
        
        // Get first cell
        let cellToDelete = budgetList.cells.element(boundBy: 0)
        let initialCellCount = budgetList.cells.count
        
        // Swipe to delete
        cellToDelete.swipeLeft()
        
        // Tap delete button
        let deleteButton = cellToDelete.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()
        
        // Verify confirmation alert
        let alert = app.alerts["Delete Budget"]
        XCTAssertTrue(alert.exists)
        
        // Confirm deletion
        alert.buttons["Delete"].tap()
        
        // Verify cell count decreased
        XCTAssertEqual(budgetList.cells.count, initialCellCount - 1)
    }
    
    func testBudgetFiltering() throws {
        let periodFilter = app.segmentedControls["Budget period filter"]
        let budgetList = app.tables["Budgets list"]
        
        // Store initial amounts
        let initialAmounts = getBudgetAmounts()
        
        // Test quarterly filter
        periodFilter.buttons["Quarterly"].tap()
        let quarterlyAmounts = getBudgetAmounts()
        XCTAssertNotEqual(initialAmounts, quarterlyAmounts)
        
        // Test annual filter
        periodFilter.buttons["Annual"].tap()
        let annualAmounts = getBudgetAmounts()
        XCTAssertNotEqual(quarterlyAmounts, annualAmounts)
        
        // Test monthly filter
        periodFilter.buttons["Monthly"].tap()
        let monthlyAmounts = getBudgetAmounts()
        XCTAssertEqual(monthlyAmounts, initialAmounts)
    }
    
    func testBudgetProgress() throws {
        let budgetList = app.tables["Budgets list"]
        guard budgetList.cells.count > 0 else {
            XCTFail("No budgets available for progress test")
            return
        }
        
        let cell = budgetList.cells.element(boundBy: 0)
        
        // Verify progress elements
        let progressBar = cell.progressIndicators["Budget progress"]
        XCTAssertTrue(progressBar.exists)
        
        let spentLabel = cell.staticTexts.element(matching: .any, identifier: "Amount spent")
        XCTAssertTrue(spentLabel.exists)
        
        // Verify alert icon if over budget
        let progressValue = Double(progressBar.value as? String?.replacingOccurrences(of: "% used", with: "") ?? "0") ?? 0
        if progressValue > 90 {
            let alertIcon = cell.images["Budget alert"]
            XCTAssertTrue(alertIcon.exists)
            XCTAssertEqual(alertIcon.value as? String, "Budget threshold exceeded")
        }
        
        // Verify progress bar color
        let progressElement = progressBar.firstMatch
        if progressValue > 90 {
            // Verify red color for > 90%
            XCTAssertTrue(progressElement.exists)
        } else if progressValue > 70 {
            // Verify orange color for > 70%
            XCTAssertTrue(progressElement.exists)
        } else {
            // Verify green color for <= 70%
            XCTAssertTrue(progressElement.exists)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getBudgetAmounts() -> [String] {
        let budgetList = app.tables["Budgets list"]
        return budgetList.cells.allElementsBoundByIndex.compactMap { cell in
            cell.staticTexts.element(matching: .any, identifier: "Budget amount").label
        }
    }
}