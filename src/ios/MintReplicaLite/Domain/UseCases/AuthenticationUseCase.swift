//
// AuthenticationUseCase.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify OAuth 2.0 client configuration in project settings
// 2. Test biometric authentication on physical devices
// 3. Review PSD2 compliance requirements with security team
// 4. Configure keychain access group settings if using app extensions

import Foundation // version: iOS 14.0+
import Combine // version: iOS 14.0+

// Relative imports based on file path
import "../../Services/AuthenticationService"
import "../Models/User"

/// Enumeration of possible authentication errors aligned with service layer
/// Requirement: Authentication Flow - Error handling for authentication flows
enum AuthenticationError: Error {
    case invalidCredentials
    case biometricNotAvailable
    case biometricNotEnabled
    case networkError
    case invalidEmail
    case invalidPassword
    case userNotFound
    case serverError
    case tokenExpired
    case refreshFailed
    case unauthorized
}

/// Protocol defining the PSD2-compliant authentication use case interface
/// Requirement: Authentication Flow - Implementation of secure user authentication
protocol AuthenticationUseCaseProtocol {
    func login(email: String, password: String) -> AnyPublisher<User, AuthenticationError>
    func loginWithBiometrics() -> AnyPublisher<User, AuthenticationError>
    func logout() -> AnyPublisher<Void, AuthenticationError>
}

/// Implementation of PSD2-compliant authentication business logic and domain rules
/// Requirement: Authentication Flow - Implementation of secure user authentication with OAuth 2.0
@objc final class AuthenticationUseCase: NSObject, AuthenticationUseCaseProtocol {
    
    // MARK: - Properties
    
    private let authService: AuthenticationService
    private let authStatePublisher = PassthroughSubject<AuthenticationState, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the authentication use case with required dependencies
    init(authService: AuthenticationService = .shared) {
        self.authService = authService
        super.init()
        
        // Set up auth state observation from service
        // Requirement: Platform Security - iOS-specific security implementations
        setupAuthStateObservation()
    }
    
    // MARK: - Public Methods
    
    /// Authenticates user with email and password using OAuth 2.0 flow
    /// Requirement: Authentication Flow - OAuth 2.0 and JWT token management
    func login(email: String, password: String) -> AnyPublisher<User, AuthenticationError> {
        return Future<User, AuthenticationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.networkError))
                return
            }
            
            // Validate credentials against domain rules
            switch self.validateCredentials(email: email, password: password) {
            case .success:
                // Proceed with authentication
                self.authService.login(email: email, password: password)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(self.mapAuthError(error)))
                            }
                        },
                        receiveValue: { success in
                            if success {
                                // Create user domain model
                                do {
                                    let user = try User(
                                        id: UUID(),
                                        email: email,
                                        firstName: "", // Will be populated from profile
                                        lastName: ""   // Will be populated from profile
                                    )
                                    promise(.success(user))
                                } catch {
                                    promise(.failure(.invalidCredentials))
                                }
                            } else {
                                promise(.failure(.invalidCredentials))
                            }
                        }
                    )
                    .store(in: &self.cancellables)
                
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Performs PSD2-compliant biometric authentication
    /// Requirement: Platform Security - Biometric authentication support
    func loginWithBiometrics() -> AnyPublisher<User, AuthenticationError> {
        return Future<User, AuthenticationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.networkError))
                return
            }
            
            self.authService.loginWithBiometrics()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(self.mapAuthError(error)))
                        }
                    },
                    receiveValue: { success in
                        if success {
                            // Create user domain model from stored credentials
                            // Note: Email will be retrieved from keychain by service
                            do {
                                let user = try User(
                                    id: UUID(),
                                    email: "stored_email", // Placeholder, will be populated
                                    firstName: "",
                                    lastName: ""
                                )
                                promise(.success(user))
                            } catch {
                                promise(.failure(.biometricNotEnabled))
                            }
                        } else {
                            promise(.failure(.biometricNotEnabled))
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    /// Logs out the current user and cleans up authentication state
    /// Requirement: Platform Security - Secure credential cleanup
    func logout() -> AnyPublisher<Void, AuthenticationError> {
        return Future<Void, AuthenticationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.networkError))
                return
            }
            
            self.authService.logout()
                .sink(
                    receiveCompletion: { _ in
                        promise(.success(()))
                    },
                    receiveValue: { _ in }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// Validates user credentials against domain rules and RFC 5322
    /// Requirement: Authentication Flow - Secure credential validation
    private func validateCredentials(email: String, password: String) -> Result<Void, AuthenticationError> {
        // Validate email format using User model
        guard User.validateEmail(email) else {
            return .failure(.invalidEmail)
        }
        
        // Validate password requirements
        guard !password.isEmpty else {
            return .failure(.invalidPassword)
        }
        
        // Password complexity requirements
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        guard password.range(of: passwordRegex, options: .regularExpression) != nil else {
            return .failure(.invalidPassword)
        }
        
        return .success(())
    }
    
    /// Maps authentication service errors to domain errors
    private func mapAuthError(_ error: AuthenticationService.AuthenticationError) -> AuthenticationError {
        switch error {
        case .invalidCredentials:
            return .invalidCredentials
        case .biometricFailed:
            return .biometricNotAvailable
        case .tokenExpired:
            return .tokenExpired
        case .refreshFailed:
            return .refreshFailed
        case .networkError:
            return .networkError
        case .unauthorized:
            return .unauthorized
        }
    }
    
    /// Sets up observation of authentication state changes
    private func setupAuthStateObservation() {
        authService.authStatePublisher
            .sink { [weak self] state in
                self?.authStatePublisher.send(state)
            }
            .store(in: &cancellables)
    }
}