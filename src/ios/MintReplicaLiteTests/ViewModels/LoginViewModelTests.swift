//
// LoginViewModelTests.swift
// MintReplicaLiteTests
//
// Human Tasks:
// 1. Verify OAuth 2.0 client credentials are configured in test environment
// 2. Run biometric authentication tests on physical devices
// 3. Ensure keychain access is properly configured for test environment
// 4. Configure test environment with mock certificates for TLS testing

// Third-party Dependencies:
// - XCTest (iOS 14.0+)
// - Combine (iOS 14.0+)

import XCTest
import Combine
@testable import MintReplicaLite

/// Test suite for LoginViewModel OAuth 2.0 and PSD2-compliant biometric authentication functionality
/// Requirements addressed:
/// - Multi-platform user authentication (1.2 Scope/Account Management)
/// - Platform-specific secure storage (2.1 High-Level Architecture Overview/Security Infrastructure)
/// - Biometric Authentication (2.4 Security Architecture/Client Security)
final class LoginViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: LoginViewModel!
    private var mockAuthService: MockAuthenticationService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
        sut = LoginViewModel(authService: mockAuthService)
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
    
    /// Test successful OAuth 2.0 login with valid credentials
    /// Requirement: Multi-platform user authentication
    func testLoginSuccess() {
        // Given
        let expectation = expectation(description: "Login success")
        let testEmail = "test@example.com"
        let testPassword = "SecurePass123!"
        
        mockAuthService.mockLoginResult = .success(true)
        mockAuthService.mockAuthStatePublisher.send(.authenticated)
        
        var receivedSuccess = false
        var loadingStates: [Bool] = []
        var errorMessages: [AuthenticationError] = []
        
        let input = LoginViewModel.Input(
            loginTrigger: Just((email: testEmail, password: testPassword)).eraseToAnyPublisher(),
            biometricTrigger: Empty().eraseToAnyPublisher(),
            viewAppeared: Empty().eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        // When
        output.loginSuccess
            .sink { _ in
                receivedSuccess = true
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.errorMessage
            .sink { error in
                errorMessages.append(error)
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
            XCTAssertTrue(receivedSuccess)
            XCTAssertEqual(loadingStates, [true, false])
            XCTAssertTrue(errorMessages.isEmpty)
        }
    }
    
    /// Test OAuth 2.0 login failure with invalid credentials
    /// Requirement: Multi-platform user authentication
    func testLoginFailure() {
        // Given
        let expectation = expectation(description: "Login failure")
        let testEmail = "invalid@example.com"
        let testPassword = "WrongPass123!"
        
        mockAuthService.mockLoginResult = .failure(.invalidCredentials)
        mockAuthService.mockAuthStatePublisher.send(.unauthenticated)
        
        var receivedSuccess = false
        var loadingStates: [Bool] = []
        var errorMessages: [AuthenticationError] = []
        
        let input = LoginViewModel.Input(
            loginTrigger: Just((email: testEmail, password: testPassword)).eraseToAnyPublisher(),
            biometricTrigger: Empty().eraseToAnyPublisher(),
            viewAppeared: Empty().eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        // When
        output.loginSuccess
            .sink { _ in
                receivedSuccess = true
            }
            .store(in: &cancellables)
        
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.errorMessage
            .sink { error in
                errorMessages.append(error)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
            XCTAssertFalse(receivedSuccess)
            XCTAssertEqual(loadingStates, [true, false])
            XCTAssertEqual(errorMessages.count, 1)
            XCTAssertEqual(errorMessages.first, .invalidCredentials)
        }
    }
    
    /// Test successful PSD2-compliant biometric authentication
    /// Requirement: Biometric Authentication
    func testBiometricLoginSuccess() {
        // Given
        let expectation = expectation(description: "Biometric login success")
        
        mockAuthService.mockBiometricResult = .success(true)
        mockAuthService.mockAuthStatePublisher.send(.authenticated)
        
        var receivedSuccess = false
        var loadingStates: [Bool] = []
        var errorMessages: [AuthenticationError] = []
        
        let input = LoginViewModel.Input(
            loginTrigger: Empty().eraseToAnyPublisher(),
            biometricTrigger: Just(()).eraseToAnyPublisher(),
            viewAppeared: Empty().eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        // When
        output.loginSuccess
            .sink { _ in
                receivedSuccess = true
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.errorMessage
            .sink { error in
                errorMessages.append(error)
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
            XCTAssertTrue(receivedSuccess)
            XCTAssertEqual(loadingStates, [true, false])
            XCTAssertTrue(errorMessages.isEmpty)
        }
    }
    
    /// Test PSD2-compliant biometric authentication failure
    /// Requirement: Biometric Authentication
    func testBiometricLoginFailure() {
        // Given
        let expectation = expectation(description: "Biometric login failure")
        
        mockAuthService.mockBiometricResult = .failure(.biometricFailed)
        mockAuthService.mockAuthStatePublisher.send(.unauthenticated)
        
        var receivedSuccess = false
        var loadingStates: [Bool] = []
        var errorMessages: [AuthenticationError] = []
        
        let input = LoginViewModel.Input(
            loginTrigger: Empty().eraseToAnyPublisher(),
            biometricTrigger: Just(()).eraseToAnyPublisher(),
            viewAppeared: Empty().eraseToAnyPublisher()
        )
        
        let output = sut.transform(input)
        
        // When
        output.loginSuccess
            .sink { _ in
                receivedSuccess = true
            }
            .store(in: &cancellables)
        
        output.isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        output.errorMessage
            .sink { error in
                errorMessages.append(error)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
            XCTAssertFalse(receivedSuccess)
            XCTAssertEqual(loadingStates, [true, false])
            XCTAssertEqual(errorMessages.count, 1)
            XCTAssertEqual(errorMessages.first, .biometricFailed)
        }
    }
}

/// Mock implementation of AuthenticationService for testing OAuth 2.0 flows
private final class MockAuthenticationService: AuthenticationService {
    var mockLoginResult: Result<Bool, AuthenticationError>?
    var mockBiometricResult: Result<Bool, AuthenticationError>?
    var mockAuthStatePublisher = CurrentValueSubject<AuthenticationState, Never>(.unauthenticated)
    
    override var authStatePublisher: AnyPublisher<AuthenticationState, Never> {
        mockAuthStatePublisher.eraseToAnyPublisher()
    }
    
    override func login(email: String, password: String) -> AnyPublisher<Bool, AuthenticationError> {
        guard let result = mockLoginResult else {
            return Fail(error: .networkError).eraseToAnyPublisher()
        }
        return result.publisher.eraseToAnyPublisher()
    }
    
    override func loginWithBiometrics() -> AnyPublisher<Bool, AuthenticationError> {
        guard let result = mockBiometricResult else {
            return Fail(error: .biometricFailed).eraseToAnyPublisher()
        }
        return result.publisher.eraseToAnyPublisher()
    }
}