//
// GoalsUITests.swift
// MintReplicaLiteUITests
//
// XCTest framework version: iOS 14.0+
//
// Human Tasks:
// 1. Ensure test device has sufficient space for app installation
// 2. Configure test device with test user credentials
// 3. Verify test environment has network connectivity
// 4. Set up test data for goal testing scenarios
// 5. Configure test device locale and region settings

import XCTest

class GoalsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Requirement: UI Testing (5.1 User Interface Design/5.1.2 Screen Layouts)
        // Configure test case for immediate failure on any error
        continueAfterFailure = false
        
        // Initialize the application instance
        app = XCUIApplication()
        
        // Reset app state and set launch arguments for testing
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["UITEST_MODE": "1"]
        
        // Launch the app in test mode
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Clean up test resources and terminate app
        app.terminate()
        app = nil
    }
    
    func testGoalCreation() throws {
        // Requirement: Goal Management (1.2 Scope/Goal Management)
        // Test goal creation functionality
        
        // Navigate to Goals tab
        app.tabBars.buttons["Goals"].tap()
        
        // Verify Goals screen is displayed
        XCTAssertTrue(app.navigationBars["Goals"].exists)
        
        // Tap add goal button
        let addButton = app.buttons["AddGoalButton"]
        XCTAssertTrue(addButton.exists)
        addButton.tap()
        
        // Verify goal creation form
        let goalForm = app.otherElements["GoalCreationForm"]
        XCTAssertTrue(goalForm.exists)
        
        // Enter goal details
        let goalNameField = app.textFields["GoalNameField"]
        goalNameField.tap()
        goalNameField.typeText("Vacation Fund")
        
        let targetAmountField = app.textFields["TargetAmountField"]
        targetAmountField.tap()
        targetAmountField.typeText("5000")
        
        // Select target date
        let datePicker = app.datePickers["TargetDatePicker"]
        datePicker.tap()
        // Set date to 1 year from now
        let calendar = Calendar.current
        let oneYearFromNow = calendar.date(byAdding: .year, value: 1, to: Date())!
        datePicker.setDate(oneYearFromNow)
        
        // Select linked account
        let accountPicker = app.pickers["LinkedAccountPicker"]
        accountPicker.tap()
        app.pickerWheels.element.adjust(toPickerWheelValue: "Savings Account")
        
        // Save the goal
        app.buttons["SaveGoalButton"].tap()
        
        // Verify goal appears in list
        let goalCell = app.cells.containing(.staticText, identifier: "Vacation Fund").element
        XCTAssertTrue(goalCell.exists)
        
        // Verify goal details
        XCTAssertTrue(goalCell.staticTexts["$5,000"].exists)
        XCTAssertTrue(goalCell.progressIndicators["GoalProgress"].exists)
        XCTAssertEqual(goalCell.progressIndicators["GoalProgress"].value as? String, "0%")
    }
    
    func testGoalProgress() throws {
        // Requirement: Goal Management (1.2 Scope/Goal Management)
        // Test goal progress tracking
        
        // Navigate to Goals tab
        app.tabBars.buttons["Goals"].tap()
        
        // Select existing goal
        let goalCell = app.cells.firstMatch
        goalCell.tap()
        
        // Verify goal detail view
        let goalDetailView = app.otherElements["GoalDetailView"]
        XCTAssertTrue(goalDetailView.exists)
        
        // Verify progress elements
        let progressBar = goalDetailView.progressIndicators["GoalProgressBar"]
        XCTAssertTrue(progressBar.exists)
        
        let currentAmount = goalDetailView.staticTexts["CurrentAmountLabel"]
        XCTAssertTrue(currentAmount.exists)
        
        let targetAmount = goalDetailView.staticTexts["TargetAmountLabel"]
        XCTAssertTrue(targetAmount.exists)
        
        let percentageLabel = goalDetailView.staticTexts["PercentageLabel"]
        XCTAssertTrue(percentageLabel.exists)
        
        // Verify linked account section
        let linkedAccountSection = goalDetailView.otherElements["LinkedAccountSection"]
        XCTAssertTrue(linkedAccountSection.exists)
        
        // Verify goal status
        let statusIndicator = goalDetailView.images["GoalStatusIndicator"]
        XCTAssertTrue(statusIndicator.exists)
        
        // Verify timeline view
        let timelineView = goalDetailView.otherElements["GoalTimelineView"]
        XCTAssertTrue(timelineView.exists)
    }
    
    func testGoalEditing() throws {
        // Requirement: Goal Management (1.2 Scope/Goal Management)
        // Test goal editing functionality
        
        // Navigate to Goals tab
        app.tabBars.buttons["Goals"].tap()
        
        // Select existing goal
        let goalCell = app.cells.firstMatch
        goalCell.tap()
        
        // Tap edit button
        app.navigationBars.buttons["EditButton"].tap()
        
        // Verify edit mode
        let editForm = app.otherElements["GoalEditForm"]
        XCTAssertTrue(editForm.exists)
        
        // Modify goal name
        let nameField = app.textFields["GoalNameField"]
        nameField.tap()
        nameField.clearText()
        nameField.typeText("Updated Vacation Fund")
        
        // Modify target amount
        let amountField = app.textFields["TargetAmountField"]
        amountField.tap()
        amountField.clearText()
        amountField.typeText("7500")
        
        // Modify target date
        let datePicker = app.datePickers["TargetDatePicker"]
        datePicker.tap()
        // Set date to 18 months from now
        let calendar = Calendar.current
        let eighteenMonthsFromNow = calendar.date(byAdding: .month, value: 18, to: Date())!
        datePicker.setDate(eighteenMonthsFromNow)
        
        // Save changes
        app.buttons["SaveButton"].tap()
        
        // Verify updated goal details
        let updatedGoalCell = app.cells.containing(.staticText, identifier: "Updated Vacation Fund").element
        XCTAssertTrue(updatedGoalCell.exists)
        XCTAssertTrue(updatedGoalCell.staticTexts["$7,500"].exists)
        
        // Verify progress recalculation
        let progressIndicator = updatedGoalCell.progressIndicators["GoalProgress"]
        XCTAssertTrue(progressIndicator.exists)
    }
    
    func testGoalDeletion() throws {
        // Requirement: Goal Management (1.2 Scope/Goal Management)
        // Test goal deletion functionality
        
        // Navigate to Goals tab
        app.tabBars.buttons["Goals"].tap()
        
        // Get initial goals count
        let initialGoalsCount = app.cells.count
        
        // Select existing goal
        let goalCell = app.cells.firstMatch
        goalCell.tap()
        
        // Tap delete button
        app.navigationBars.buttons["DeleteButton"].tap()
        
        // Verify delete confirmation alert
        let deleteAlert = app.alerts["DeleteGoalAlert"]
        XCTAssertTrue(deleteAlert.exists)
        
        // Verify alert buttons
        XCTAssertTrue(deleteAlert.buttons["Cancel"].exists)
        XCTAssertTrue(deleteAlert.buttons["Delete"].exists)
        
        // Confirm deletion
        deleteAlert.buttons["Delete"].tap()
        
        // Verify goal is removed
        let finalGoalsCount = app.cells.count
        XCTAssertEqual(finalGoalsCount, initialGoalsCount - 1)
        
        // Verify empty state if last goal
        if finalGoalsCount == 0 {
            let emptyStateView = app.otherElements["EmptyStateView"]
            XCTAssertTrue(emptyStateView.exists)
        }
    }
    
    func testGoalListEmptyState() throws {
        // Requirement: UI Testing (5.1 User Interface Design/5.1.2 Screen Layouts)
        // Test empty state display
        
        // Navigate to Goals tab
        app.tabBars.buttons["Goals"].tap()
        
        // Delete all existing goals
        while app.cells.count > 0 {
            let goalCell = app.cells.firstMatch
            goalCell.tap()
            app.navigationBars.buttons["DeleteButton"].tap()
            app.alerts["DeleteGoalAlert"].buttons["Delete"].tap()
        }
        
        // Verify empty state view
        let emptyStateView = app.otherElements["EmptyStateView"]
        XCTAssertTrue(emptyStateView.exists)
        
        // Verify empty state message
        let emptyMessage = emptyStateView.staticTexts["EmptyStateMessage"]
        XCTAssertTrue(emptyMessage.exists)
        XCTAssertEqual(emptyMessage.label, "No goals yet. Tap + to create your first goal.")
        
        // Verify add goal button
        let addButton = emptyStateView.buttons["AddGoalButton"]
        XCTAssertTrue(addButton.exists)
        XCTAssertTrue(addButton.isEnabled)
        
        // Tap add goal button
        addButton.tap()
        
        // Verify navigation to goal creation
        let goalCreationForm = app.otherElements["GoalCreationForm"]
        XCTAssertTrue(goalCreationForm.exists)
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else { return }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}