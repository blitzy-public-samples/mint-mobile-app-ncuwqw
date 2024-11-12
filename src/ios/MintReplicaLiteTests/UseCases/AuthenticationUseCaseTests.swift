//
// AuthenticationUseCaseTests.swift
// MintReplicaLiteTests
//
// HUMAN TASKS:
// 1. Verify OAuth 2.0 client configuration in test environment
// 2. Test biometric authentication on physical iOS devices
// 3. Configure test keychain access for CI/CD pipeline
// 4. Review PSD2 compliance test coverage with security team

import XCTest // version: iOS 14.0+
import Combine // version: iOS 14.0+
@testable import MintReplicaLite

/// Test suite for AuthenticationUseCase verifying OAuth 2.0 and PSD2-compliant functionality
/// Requirement: Authentication Flow - Verify secure user authentication implementation
final class AuthenticationUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: AuthenticationUseCase!
    private var mockAuthService: MockAuthenticationService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
        sut = AuthenticationUseCase(authService: mockAuthService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        mockAuthService = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests successful OAuth 2.0 login flow with valid credentials
    /// Requirement: Authentication Flow - OAuth 2.0 and JWT token management
    func testLoginSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Login success")
        let validEmail = "test@example.com"
        let validPassword = "Password123!"
        var receivedError: AuthenticationError?
        var loginSuccess = false
        
        mockAuthService.loginResult = .success(true)
        
        // When
        sut.login(email: validEmail, password: validPassword)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    loginSuccess = true
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedError, "No error should be received")
        XCTAssertTrue(loginSuccess, "Login should succeed")
        XCTAssertTrue(mockAuthService.loginCalled, "Authentication service login should be called")
    }
    
    /// Tests login failure with invalid RFC 5322 email format
    /// Requirement: Authentication Flow - Secure credential validation
    func testLoginInvalidEmail() {
        // Given
        let expectation = XCTestExpectation(description: "Invalid email")
        let invalidEmail = "invalid-email"
        let password = "Password123!"
        var receivedError: AuthenticationError?
        
        // When
        sut.login(email: invalidEmail, password: password)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, .invalidEmail, "Should receive invalid email error")
        XCTAssertFalse(mockAuthService.loginCalled, "Auth service should not be called")
    }
    
    /// Tests login failure with invalid password format
    /// Requirement: Authentication Flow - Secure credential validation
    func testLoginInvalidPassword() {
        // Given
        let expectation = XCTestExpectation(description: "Invalid password")
        let email = "test@example.com"
        let invalidPassword = "weak"
        var receivedError: AuthenticationError?
        
        // When
        sut.login(email: email, password: invalidPassword)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, .invalidPassword, "Should receive invalid password error")
        XCTAssertFalse(mockAuthService.loginCalled, "Auth service should not be called")
    }
    
    /// Tests successful PSD2-compliant biometric authentication
    /// Requirement: Platform Security - iOS-specific biometric authentication
    func testBiometricLoginSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Biometric login success")
        var receivedError: AuthenticationError?
        var loginSuccess = false
        
        mockAuthService.biometricLoginResult = .success(true)
        
        // When
        sut.loginWithBiometrics()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    loginSuccess = true
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedError, "No error should be received")
        XCTAssertTrue(loginSuccess, "Biometric login should succeed")
        XCTAssertTrue(mockAuthService.biometricLoginCalled, "Biometric login should be called")
    }
    
    /// Tests biometric authentication when biometrics are unavailable
    /// Requirement: Platform Security - Biometric authentication error handling
    func testBiometricLoginUnavailable() {
        // Given
        let expectation = XCTestExpectation(description: "Biometric unavailable")
        var receivedError: AuthenticationError?
        
        mockAuthService.biometricLoginResult = .failure(.biometricFailed)
        
        // When
        sut.loginWithBiometrics()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, .biometricNotAvailable, "Should receive biometric not available error")
    }
    
    /// Tests successful OAuth 2.0 logout flow
    /// Requirement: Platform Security - Secure credential cleanup
    func testLogoutSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Logout success")
        var receivedError: AuthenticationError?
        var logoutSuccess = false
        
        mockAuthService.logoutResult = .success(())
        
        // When
        sut.logout()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    logoutSuccess = true
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedError, "No error should be received")
        XCTAssertTrue(logoutSuccess, "Logout should succeed")
        XCTAssertTrue(mockAuthService.logoutCalled, "Logout should be called")
    }
}

// MARK: - Mock Authentication Service

/// Mock implementation of AuthenticationService for testing OAuth 2.0 flows
private class MockAuthenticationService: AuthenticationService {
    var loginCalled = false
    var biometricLoginCalled = false
    var logoutCalled = false
    
    var loginResult: Result<Bool, AuthenticationError> = .success(false)
    var biometricLoginResult: Result<Bool, AuthenticationError> = .success(false)
    var logoutResult: Result<Void, Never> = .success(())
    
    let authStatePublisher = PassthroughSubject<AuthenticationState, Never>()
    
    override func login(email: String, password: String) -> AnyPublisher<Bool, AuthenticationError> {
        loginCalled = true
        return Future<Bool, AuthenticationError> { promise in
            promise(self.loginResult)
        }.eraseToAnyPublisher()
    }
    
    override func loginWithBiometrics() -> AnyPublisher<Bool, AuthenticationError> {
        biometricLoginCalled = true
        return Future<Bool, AuthenticationError> { promise in
            promise(self.biometricLoginResult)
        }.eraseToAnyPublisher()
    }
    
    override func logout() -> AnyPublisher<Void, Never> {
        logoutCalled = true
        return Future<Void, Never> { promise in
            promise(self.logoutResult)
        }.eraseToAnyPublisher()
    }
}