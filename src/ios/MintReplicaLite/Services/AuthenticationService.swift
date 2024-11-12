//
// AuthenticationService.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Configure OAuth 2.0 client credentials in project configuration
// 2. Review and update authentication API endpoints for production
// 3. Test biometric authentication on physical devices
// 4. Verify keychain access group settings for app extensions

import Foundation // version: iOS 14.0+
import Combine // version: iOS 14.0+

// Relative imports based on file path
import "../Common/Utils/BiometricAuthManager"
import "../Common/Utils/KeychainManager"
import "../Data/Network/APIClient"

/// Custom error types for authentication operations
/// Requirement: Multi-platform user authentication - Error handling for authentication flows
enum AuthenticationError: Error {
    case invalidCredentials
    case biometricFailed
    case tokenExpired
    case refreshFailed
    case networkError
    case unauthorized
}

/// Possible states of user authentication
/// Requirement: Multi-platform user authentication - State management
enum AuthenticationState {
    case authenticated
    case unauthenticated
    case refreshing
    case biometricInProgress
}

/// Core authentication service managing user authentication and token management
/// Requirement: OAuth 2.0 and JWT-based authentication - Implementation of secure authentication protocols
@objc final class AuthenticationService {
    
    // MARK: - Properties
    
    private var accessToken: String?
    private var refreshToken: String?
    private(set) var isAuthenticated: Bool = false
    
    private let authStatePublisher = PassthroughSubject<AuthenticationState, Never>()
    private let keychainManager: KeychainManager
    private let biometricManager: BiometricAuthManager
    private let apiClient: APIClient
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    
    /// Shared instance of AuthenticationService
    static let shared = AuthenticationService()
    
    // MARK: - Initialization
    
    private init() {
        // Initialize dependencies
        self.keychainManager = KeychainManager.shared
        self.biometricManager = BiometricAuthManager.shared
        self.apiClient = APIClient.shared
        
        // Set up token observers
        setupTokenObservers()
        
        // Check for existing valid tokens
        checkExistingTokens()
    }
    
    // MARK: - Public Methods
    
    /// Authenticates user with email and password using OAuth 2.0
    /// Requirement: OAuth 2.0 and JWT-based authentication - Secure token management
    func login(email: String, password: String) -> AnyPublisher<Bool, AuthenticationError> {
        return Future<Bool, AuthenticationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.networkError))
                return
            }
            
            // Validate input credentials
            guard !email.isEmpty, !password.isEmpty else {
                promise(.failure(.invalidCredentials))
                return
            }
            
            // Prepare OAuth authentication request
            let authRequest = APIRouter.authenticate(email: email, password: password)
            
            self.apiClient.request(authRequest, responseType: AuthResponse.self)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            promise(.failure(self.mapAPIError(error)))
                        case .finished:
                            break
                        }
                    },
                    receiveValue: { [weak self] response in
                        guard let self = self else { return }
                        
                        // Store tokens securely with AES-256
                        self.storeTokens(
                            accessToken: response.accessToken,
                            refreshToken: response.refreshToken
                        )
                        
                        // Update authentication state
                        self.isAuthenticated = true
                        self.authStatePublisher.send(.authenticated)
                        
                        promise(.success(true))
                    }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    /// Authenticates user using PSD2-compliant biometric authentication
    /// Requirement: Platform-specific secure storage - Biometric authentication
    func loginWithBiometrics() -> AnyPublisher<Bool, AuthenticationError> {
        return Future<Bool, AuthenticationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.networkError))
                return
            }
            
            // Check biometric availability
            guard self.biometricManager.checkBiometricAvailability() else {
                promise(.failure(.biometricFailed))
                return
            }
            
            // Retrieve encrypted credentials
            guard let encryptedCredentials = try? self.keychainManager.retrieve(key: "biometric_credentials")
                .get() else {
                promise(.failure(.biometricFailed))
                return
            }
            
            // Trigger biometric authentication
            self.biometricManager.authenticateUser(
                reason: "Log in to your account"
            ) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    // Decrypt and validate stored credentials
                    do {
                        let credentials = try JSONDecoder().decode(
                            StoredCredentials.self,
                            from: encryptedCredentials
                        )
                        
                        // Attempt token refresh
                        self.refreshTokens()
                            .sink(
                                receiveCompletion: { completion in
                                    switch completion {
                                    case .failure(let error):
                                        promise(.failure(error))
                                    case .finished:
                                        break
                                    }
                                },
                                receiveValue: { success in
                                    promise(.success(success))
                                }
                            )
                            .store(in: &self.cancellables)
                        
                    } catch {
                        promise(.failure(.biometricFailed))
                    }
                    
                case .failure:
                    promise(.failure(.biometricFailed))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Logs out user and securely clears authentication state
    /// Requirement: Platform-specific secure storage - Secure credential cleanup
    func logout() -> AnyPublisher<Void, Never> {
        return Future<Void, Never> { [weak self] promise in
            guard let self = self else {
                promise(.success(()))
                return
            }
            
            // Invalidate tokens on server
            let logoutRequest = APIRouter.logout(token: self.accessToken ?? "")
            
            self.apiClient.request(logoutRequest, responseType: EmptyResponse.self)
                .sink(
                    receiveCompletion: { _ in
                        // Clear stored tokens from keychain
                        _ = try? self.keychainManager.delete(key: "access_token")
                        _ = try? self.keychainManager.delete(key: "refresh_token")
                        _ = try? self.keychainManager.delete(key: "biometric_credentials")
                        
                        // Reset authentication state
                        self.accessToken = nil
                        self.refreshToken = nil
                        self.isAuthenticated = false
                        
                        // Notify observers
                        self.authStatePublisher.send(.unauthenticated)
                        
                        promise(.success(()))
                    },
                    receiveValue: { _ in }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// Refreshes OAuth authentication tokens
    /// Requirement: OAuth 2.0 and JWT-based authentication - Token refresh
    private func refreshTokens() -> AnyPublisher<Bool, AuthenticationError> {
        return Future<Bool, AuthenticationError> { [weak self] promise in
            guard let self = self,
                  let refreshToken = self.refreshToken else {
                promise(.failure(.refreshFailed))
                return
            }
            
            // Update authentication state
            self.authStatePublisher.send(.refreshing)
            
            // Make OAuth token refresh request
            let refreshRequest = APIRouter.refreshToken(token: refreshToken)
            
            self.apiClient.request(refreshRequest, responseType: AuthResponse.self)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            self.authStatePublisher.send(.unauthenticated)
                            promise(.failure(self.mapAPIError(error)))
                        case .finished:
                            break
                        }
                    },
                    receiveValue: { [weak self] response in
                        guard let self = self else { return }
                        
                        // Update stored tokens in keychain
                        self.storeTokens(
                            accessToken: response.accessToken,
                            refreshToken: response.refreshToken
                        )
                        
                        // Update authentication state
                        self.isAuthenticated = true
                        self.authStatePublisher.send(.authenticated)
                        
                        promise(.success(true))
                    }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    /// Stores authentication tokens securely
    /// Requirement: Platform-specific secure storage - iOS Keychain storage
    private func storeTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        // Store tokens in keychain with AES-256 encryption
        _ = try? keychainManager.save(
            data: accessToken.data(using: .utf8)!,
            key: "access_token"
        )
        
        _ = try? keychainManager.save(
            data: refreshToken.data(using: .utf8)!,
            key: "refresh_token"
        )
    }
    
    /// Checks for existing valid tokens on initialization
    /// Requirement: Multi-platform user authentication - Session persistence
    private func checkExistingTokens() {
        if let accessTokenData = try? keychainManager.retrieve(key: "access_token").get(),
           let refreshTokenData = try? keychainManager.retrieve(key: "refresh_token").get(),
           let accessToken = String(data: accessTokenData, encoding: .utf8),
           let refreshToken = String(data: refreshTokenData, encoding: .utf8) {
            
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            
            // Validate tokens and refresh if needed
            refreshTokens()
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] success in
                        self?.isAuthenticated = success
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    /// Sets up token expiration observers
    /// Requirement: OAuth 2.0 and JWT-based authentication - Token lifecycle
    private func setupTokenObservers() {
        // Monitor token expiration
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      self.isAuthenticated,
                      let accessToken = self.accessToken else { return }
                
                // Check token expiration
                if self.isTokenExpired(accessToken) {
                    self.refreshTokens()
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { _ in }
                        )
                        .store(in: &self.cancellables)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Checks if a JWT token is expired
    /// Requirement: OAuth 2.0 and JWT-based authentication - Token validation
    private func isTokenExpired(_ token: String) -> Bool {
        guard let jwt = try? decode(jwt: token),
              let expirationDate = jwt.expirationDate else {
            return true
        }
        
        // Add buffer time before actual expiration
        return expirationDate.addingTimeInterval(-300) < Date()
    }
    
    /// Maps API errors to authentication errors
    private func mapAPIError(_ error: APIError) -> AuthenticationError {
        switch error {
        case .unauthorized:
            return .unauthorized
        case .invalidResponse:
            return .invalidCredentials
        default:
            return .networkError
        }
    }
}

// MARK: - Supporting Types

private struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

private struct StoredCredentials: Codable {
    let email: String
    let refreshToken: String
}

private struct EmptyResponse: Decodable {}