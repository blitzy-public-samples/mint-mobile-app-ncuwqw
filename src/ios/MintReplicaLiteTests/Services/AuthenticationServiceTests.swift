//
// AuthenticationServiceTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Configure test OAuth credentials in test configuration file
// 2. Verify test keychain access group settings
// 3. Run tests on physical devices to validate biometric authentication
// 4. Review test coverage reports and add additional test cases if needed

import XCTest // version: iOS 14.0+
import Combine // version: iOS 14.0+
@testable import MintReplicaLite

/// Test suite for AuthenticationService verifying OAuth 2.0, JWT tokens, and PSD2 biometric authentication
/// Requirement: Multi-platform user authentication - Verify secure OAuth 2.0 implementation
final class AuthenticationServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: AuthenticationService!
    private var mockKeychainManager: KeychainManager!
    private var mockBiometricManager: BiometricAuthManager!
    private var cancellables: Set<AnyCancellable>!
    
    // Test data
    private let testEmail = "test@example.com"
    private let testPassword = "TestPassword123!"
    private let testAccessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test"
    private let testRefreshToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh"
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Initialize test dependencies
        mockKeychainManager = KeychainManager.shared
        mockBiometricManager = BiometricAuthManager.shared
        sut = AuthenticationService.shared
        cancellables = Set<AnyCancellable>()
        
        // Clear any existing keychain data
        _ = try? mockKeychainManager.clear()
    }
    
    override func tearDown() {
        // Clean up test data
        _ = try? mockKeychainManager.clear()
        cancellables.removeAll()
        sut = nil
        mockKeychainManager = nil
        mockBiometricManager = nil
        
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests successful OAuth 2.0 login flow
    /// Requirement: OAuth 2.0 and JWT-based authentication - Validate secure authentication protocol
    func testLoginSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Login success")
        var authenticationResult: Bool?
        var authenticationError: AuthenticationError?
        
        // When
        sut.login(email: testEmail, password: testPassword)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        authenticationError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { result in
                    authenticationResult = result
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(authenticationError, "No error should occur during successful login")
        XCTAssertEqual(authenticationResult, true, "Login should be successful")
        XCTAssertTrue(sut.isAuthenticated, "Authentication state should be true")
        
        // Verify tokens stored in keychain
        let accessTokenResult = mockKeychainManager.retrieve(key: "access_token")
        let refreshTokenResult = mockKeychainManager.retrieve(key: "refresh_token")
        
        XCTAssertNotNil(try? accessTokenResult.get(), "Access token should be stored in keychain")
        XCTAssertNotNil(try? refreshTokenResult.get(), "Refresh token should be stored in keychain")
    }
    
    /// Tests OAuth login failure with invalid credentials
    /// Requirement: Multi-platform user authentication - Error handling
    func testLoginFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Login failure")
        let invalidEmail = "invalid@example.com"
        let invalidPassword = "wrong"
        var authenticationError: AuthenticationError?
        
        // When
        sut.login(email: invalidEmail, password: invalidPassword)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        authenticationError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(authenticationError, .invalidCredentials, "Should receive invalid credentials error")
        XCTAssertFalse(sut.isAuthenticated, "Authentication state should be false")
        
        // Verify no tokens stored in keychain
        let accessTokenResult = mockKeychainManager.retrieve(key: "access_token")
        let refreshTokenResult = mockKeychainManager.retrieve(key: "refresh_token")
        
        XCTAssertThrowsError(try accessTokenResult.get(), "No access token should be stored")
        XCTAssertThrowsError(try refreshTokenResult.get(), "No refresh token should be stored")
    }
    
    /// Tests successful PSD2-compliant biometric authentication
    /// Requirement: Platform-specific secure storage - Biometric authentication
    func testBiometricLoginSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Biometric login")
        var authenticationResult: Bool?
        var authenticationError: AuthenticationError?
        
        // Store test tokens in keychain
        _ = try? mockKeychainManager.save(
            data: testAccessToken.data(using: .utf8)!,
            key: "access_token"
        )
        _ = try? mockKeychainManager.save(
            data: testRefreshToken.data(using: .utf8)!,
            key: "refresh_token"
        )
        
        // When
        sut.loginWithBiometrics()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        authenticationError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { result in
                    authenticationResult = result
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(authenticationError, "No error should occur during biometric login")
        XCTAssertEqual(authenticationResult, true, "Biometric login should be successful")
        XCTAssertTrue(sut.isAuthenticated, "Authentication state should be true")
    }
    
    /// Tests user logout and secure cleanup
    /// Requirement: Platform-specific secure storage - Secure credential cleanup
    func testLogout() {
        // Given
        let expectation = XCTestExpectation(description: "Logout")
        
        // Set up authenticated state
        _ = try? mockKeychainManager.save(
            data: testAccessToken.data(using: .utf8)!,
            key: "access_token"
        )
        _ = try? mockKeychainManager.save(
            data: testRefreshToken.data(using: .utf8)!,
            key: "refresh_token"
        )
        
        // When
        sut.logout()
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertFalse(sut.isAuthenticated, "Authentication state should be false")
        
        // Verify tokens removed from keychain
        let accessTokenResult = mockKeychainManager.retrieve(key: "access_token")
        let refreshTokenResult = mockKeychainManager.retrieve(key: "refresh_token")
        
        XCTAssertThrowsError(try accessTokenResult.get(), "Access token should be removed")
        XCTAssertThrowsError(try refreshTokenResult.get(), "Refresh token should be removed")
    }
    
    /// Tests OAuth token refresh mechanism
    /// Requirement: OAuth 2.0 and JWT-based authentication - Token refresh
    func testTokenRefresh() {
        // Given
        let expectation = XCTestExpectation(description: "Token refresh")
        var refreshResult: Bool?
        var refreshError: AuthenticationError?
        
        // Store expired access token and valid refresh token
        _ = try? mockKeychainManager.save(
            data: testAccessToken.data(using: .utf8)!,
            key: "access_token"
        )
        _ = try? mockKeychainManager.save(
            data: testRefreshToken.data(using: .utf8)!,
            key: "refresh_token"
        )
        
        // When
        sut.refreshTokens()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        refreshError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { result in
                    refreshResult = result
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(refreshError, "No error should occur during token refresh")
        XCTAssertEqual(refreshResult, true, "Token refresh should be successful")
        XCTAssertTrue(sut.isAuthenticated, "Authentication state should remain true")
        
        // Verify new tokens stored in keychain
        let accessTokenResult = mockKeychainManager.retrieve(key: "access_token")
        let refreshTokenResult = mockKeychainManager.retrieve(key: "refresh_token")
        
        XCTAssertNotNil(try? accessTokenResult.get(), "New access token should be stored")
        XCTAssertNotNil(try? refreshTokenResult.get(), "New refresh token should be stored")
    }
}