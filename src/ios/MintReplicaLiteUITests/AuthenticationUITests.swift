//
// AuthenticationUITests.swift
// MintReplicaLiteUITests
//
// Human Tasks:
// 1. Configure test environment with valid OAuth 2.0 test credentials
// 2. Set up biometric authentication simulation in test scheme
// 3. Ensure test keychain is properly reset between test runs
// 4. Verify test device supports biometric authentication
// 5. Configure test timeouts based on CI/CD environment performance

// Third-party Dependencies:
// - XCTest (iOS 14.0+)
// - XCUITest (iOS 14.0+)

import XCTest

/// UI test suite for PSD2-compliant authentication flows
/// Requirements addressed:
/// - Multi-platform user authentication (1.2 Scope/Account Management)
/// - Biometric Authentication (2.4 Security Architecture/Client Security)
/// - Platform-specific secure storage (2.1 High-Level Architecture Overview/Security Infrastructure)
final class AuthenticationUITests: XCTestCase {
    
    // MARK: - Properties
    
    private var app: XCUIApplication!
    private let defaultTimeout: TimeInterval = 10.0
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Configure app for testing
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = [
            "RESET_KEYCHAIN": "1",
            "DISABLE_ANIMATIONS": "1"
        ]
        
        app.launch()
        
        // Requirement: Multi-platform user authentication
        // Wait for login screen to appear
        let emailTextField = app.textFields["loginEmailTextField"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: defaultTimeout))
    }
    
    override func tearDownWithError() throws {
        // Requirement: Platform-specific secure storage
        // Clean up keychain data
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        secItemClasses.forEach { secItemClass in
            let query = [secItemClass: kSecMatchLimitAll]
            SecItemDelete(query as CFDictionary)
        }
        
        // Reset biometric simulation state
        app.terminate()
        app = nil
    }
    
    // MARK: - Test Cases
    
    func testSuccessfulLogin() throws {
        // Requirement: Multi-platform user authentication
        let emailTextField = app.textFields["loginEmailTextField"]
        let passwordTextField = app.secureTextFields["loginPasswordTextField"]
        let loginButton = app.buttons["loginButton"]
        let loadingIndicator = app.activityIndicators["loginLoadingIndicator"]
        
        // Enter valid OAuth 2.0 compliant credentials
        emailTextField.tap()
        emailTextField.typeText("test.user@example.com")
        
        passwordTextField.tap()
        passwordTextField.typeText("TestPassword123!")
        
        // Verify login button is enabled
        XCTAssertTrue(loginButton.isEnabled)
        
        // Attempt login
        loginButton.tap()
        
        // Verify loading state
        XCTAssertTrue(loadingIndicator.exists)
        
        // Wait for dashboard screen
        let dashboardView = app.otherElements["dashboardView"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: defaultTimeout))
        
        // Requirement: Platform-specific secure storage
        // Verify OAuth token presence in keychain
        let tokenQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "oauth_token",
            kSecReturnData: true
        ] as [String: Any]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(tokenQuery as CFDictionary, &result)
        XCTAssertEqual(status, errSecSuccess)
    }
    
    func testLoginWithInvalidCredentials() throws {
        let emailTextField = app.textFields["loginEmailTextField"]
        let passwordTextField = app.secureTextFields["loginPasswordTextField"]
        let loginButton = app.buttons["loginButton"]
        let errorLabel = app.staticTexts["loginErrorLabel"]
        
        // Test invalid email format
        emailTextField.tap()
        emailTextField.typeText("invalid.email")
        
        passwordTextField.tap()
        passwordTextField.typeText("password")
        
        loginButton.tap()
        
        // Verify error message
        XCTAssertTrue(errorLabel.waitForExistence(timeout: defaultTimeout))
        XCTAssertTrue(errorLabel.label.contains("Invalid email format"))
        
        // Clear fields and test invalid password
        emailTextField.tap()
        emailTextField.clearText()
        emailTextField.typeText("test.user@example.com")
        
        passwordTextField.tap()
        passwordTextField.clearText()
        passwordTextField.typeText("weak")
        
        loginButton.tap()
        
        // Verify PSD2 password requirements error
        XCTAssertTrue(errorLabel.waitForExistence(timeout: defaultTimeout))
        XCTAssertTrue(errorLabel.label.contains("Password must meet security requirements"))
        
        // Verify user remains on login screen
        XCTAssertTrue(emailTextField.exists)
        
        // Requirement: Platform-specific secure storage
        // Verify no token in keychain
        let tokenQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "oauth_token",
            kSecReturnData: true
        ] as [String: Any]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(tokenQuery as CFDictionary, &result)
        XCTAssertEqual(status, errSecItemNotFound)
    }
    
    func testBiometricAuthentication() throws {
        // Requirement: Biometric Authentication
        let biometricLoginButton = app.buttons["biometricLoginButton"]
        let loadingIndicator = app.activityIndicators["loginLoadingIndicator"]
        
        // Verify biometric login availability
        XCTAssertTrue(biometricLoginButton.waitForExistence(timeout: defaultTimeout))
        XCTAssertTrue(biometricLoginButton.isEnabled)
        
        // Trigger biometric authentication
        biometricLoginButton.tap()
        
        // Simulate successful biometric match
        let biometricPrompt = app.alerts.firstMatch
        XCTAssertTrue(biometricPrompt.waitForExistence(timeout: defaultTimeout))
        biometricPrompt.buttons["Authenticate"].tap()
        
        // Verify loading state
        XCTAssertTrue(loadingIndicator.exists)
        
        // Wait for successful authentication
        let dashboardView = app.otherElements["dashboardView"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: defaultTimeout))
        
        // Verify biometric token in keychain
        let biometricTokenQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "biometric_token",
            kSecReturnData: true
        ] as [String: Any]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(biometricTokenQuery as CFDictionary, &result)
        XCTAssertEqual(status, errSecSuccess)
    }
    
    func testBiometricAuthenticationFailure() throws {
        let biometricLoginButton = app.buttons["biometricLoginButton"]
        let errorLabel = app.staticTexts["loginErrorLabel"]
        
        // Verify biometric login availability
        XCTAssertTrue(biometricLoginButton.waitForExistence(timeout: defaultTimeout))
        
        // Trigger biometric authentication
        biometricLoginButton.tap()
        
        // Simulate biometric failure
        let biometricPrompt = app.alerts.firstMatch
        XCTAssertTrue(biometricPrompt.waitForExistence(timeout: defaultTimeout))
        biometricPrompt.buttons["Cancel"].tap()
        
        // Verify error message
        XCTAssertTrue(errorLabel.waitForExistence(timeout: defaultTimeout))
        XCTAssertTrue(errorLabel.label.contains("Biometric authentication failed"))
        
        // Verify fallback to password login
        let emailTextField = app.textFields["loginEmailTextField"]
        let passwordTextField = app.secureTextFields["loginPasswordTextField"]
        XCTAssertTrue(emailTextField.isEnabled)
        XCTAssertTrue(passwordTextField.isEnabled)
        
        // Verify no biometric token in keychain
        let biometricTokenQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "biometric_token",
            kSecReturnData: true
        ] as [String: Any]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(biometricTokenQuery as CFDictionary, &result)
        XCTAssertEqual(status, errSecItemNotFound)
    }
    
    func testLoginFieldValidation() throws {
        let emailTextField = app.textFields["loginEmailTextField"]
        let passwordTextField = app.secureTextFields["loginPasswordTextField"]
        let loginButton = app.buttons["loginButton"]
        let errorLabel = app.staticTexts["loginErrorLabel"]
        
        // Test empty email validation
        emailTextField.tap()
        emailTextField.typeText("")
        
        passwordTextField.tap()
        passwordTextField.typeText("ValidPassword123!")
        
        loginButton.tap()
        
        XCTAssertTrue(errorLabel.waitForExistence(timeout: defaultTimeout))
        XCTAssertTrue(errorLabel.label.contains("Email is required"))
        
        // Test malformed email validation
        emailTextField.tap()
        emailTextField.typeText("invalid@email")
        
        loginButton.tap()
        
        XCTAssertTrue(errorLabel.label.contains("Invalid email format"))
        
        // Test empty password validation
        emailTextField.tap()
        emailTextField.clearText()
        emailTextField.typeText("test.user@example.com")
        
        passwordTextField.tap()
        passwordTextField.clearText()
        
        loginButton.tap()
        
        XCTAssertTrue(errorLabel.label.contains("Password is required"))
        
        // Test PSD2 password complexity requirements
        passwordTextField.tap()
        passwordTextField.typeText("weak")
        
        loginButton.tap()
        
        XCTAssertTrue(errorLabel.label.contains("Password must contain at least"))
        
        // Verify login button state
        XCTAssertFalse(loginButton.isEnabled)
        
        // Enter valid password and verify button state
        passwordTextField.tap()
        passwordTextField.clearText()
        passwordTextField.typeText("StrongPassword123!")
        
        XCTAssertTrue(loginButton.isEnabled)
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        // Select all text and delete
        tap()
        press(forDuration: 1.0)
        
        let selectAll = XCUIApplication().menuItems["Select All"]
        if selectAll.exists {
            selectAll.tap()
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count))
        }
    }
}