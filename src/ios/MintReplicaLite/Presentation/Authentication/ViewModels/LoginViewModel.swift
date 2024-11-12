//
// LoginViewModel.swift
// MintReplicaLite
//
// Human Tasks:
// 1. Verify OAuth 2.0 client credentials are configured in project settings
// 2. Test biometric authentication on physical devices
// 3. Ensure keychain access is properly configured for token storage
// 4. Review error messages with UX team for user-friendly display

// Third-party Dependencies:
// - Foundation (iOS 14.0+)
// - Combine (iOS 14.0+)

import Foundation
import Combine

// Relative imports
import "../../../Common/Protocols/ViewModelType"
import "../../../Services/AuthenticationService"
import "../../../Common/Utils/BiometricAuthManager"

/// ViewModel implementing MVVM pattern for PSD2-compliant login functionality
/// Requirements addressed:
/// - Multi-platform user authentication (1.2 Scope/Account Management)
/// - Platform-specific secure storage (2.1 High-Level Architecture Overview/Security Infrastructure)
/// - Biometric Authentication (2.4 Security Architecture/Client Security)
@MainActor final class LoginViewModel: ViewModelType {
    
    // MARK: - Type Definitions
    
    /// Input events from the view layer
    struct Input {
        /// Email/password login trigger
        let loginTrigger: AnyPublisher<(email: String, password: String), Never>
        /// Biometric authentication trigger
        let biometricTrigger: AnyPublisher<Void, Never>
        /// View appeared event
        let viewAppeared: AnyPublisher<Void, Never>
    }
    
    /// Output state for view binding
    struct Output {
        /// Loading state publisher
        let isLoading: AnyPublisher<Bool, Never>
        /// Success event publisher
        let loginSuccess: AnyPublisher<Void, Never>
        /// Error message publisher
        let errorMessage: AnyPublisher<AuthenticationError, Never>
        /// Biometric availability publisher
        let isBiometricAvailable: AnyPublisher<Bool, Never>
    }
    
    // MARK: - Private Properties
    
    private let loginSuccessSubject = PassthroughSubject<Void, Never>()
    private let errorMessageSubject = PassthroughSubject<AuthenticationError, Never>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isBiometricAvailableSubject = CurrentValueSubject<Bool, Never>(false)
    private var cancellables = Set<AnyCancellable>()
    
    private let authService: AuthenticationService
    private let biometricManager: BiometricAuthManager
    
    // MARK: - Initialization
    
    init(
        authService: AuthenticationService = .shared,
        biometricManager: BiometricAuthManager = .shared
    ) {
        self.authService = authService
        self.biometricManager = biometricManager
        
        // Check biometric availability on initialization
        checkBiometricAvailability()
        
        // Subscribe to authentication state changes
        setupAuthStateObserver()
    }
    
    // MARK: - ViewModelType Implementation
    
    func transform(_ input: Input) -> Output {
        // Handle email/password login
        input.loginTrigger
            .flatMap { [weak self] credentials -> AnyPublisher<Void, AuthenticationError> in
                guard let self = self else {
                    return Fail(error: AuthenticationError.unauthorized).eraseToAnyPublisher()
                }
                return self.loginWithCredentials(email: credentials.email, password: credentials.password)
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessageSubject.send(error)
                    }
                },
                receiveValue: { [weak self] in
                    self?.loginSuccessSubject.send()
                }
            )
            .store(in: &cancellables)
        
        // Handle biometric authentication
        input.biometricTrigger
            .flatMap { [weak self] _ -> AnyPublisher<Void, AuthenticationError> in
                guard let self = self else {
                    return Fail(error: AuthenticationError.unauthorized).eraseToAnyPublisher()
                }
                return self.loginWithBiometrics()
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessageSubject.send(error)
                    }
                },
                receiveValue: { [weak self] in
                    self?.loginSuccessSubject.send()
                }
            )
            .store(in: &cancellables)
        
        // Check biometric availability when view appears
        input.viewAppeared
            .sink { [weak self] _ in
                self?.checkBiometricAvailability()
            }
            .store(in: &cancellables)
        
        return Output(
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            loginSuccess: loginSuccessSubject.eraseToAnyPublisher(),
            errorMessage: errorMessageSubject.eraseToAnyPublisher(),
            isBiometricAvailable: isBiometricAvailableSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    
    /// Handles OAuth 2.0 email and password login
    /// Requirement: Multi-platform user authentication
    private func loginWithCredentials(email: String, password: String) -> AnyPublisher<Void, AuthenticationError> {
        isLoadingSubject.send(true)
        
        return authService.login(email: email, password: password)
            .handleEvents(
                receiveSubscription: { [weak self] _ in
                    self?.isLoadingSubject.send(true)
                },
                receiveCompletion: { [weak self] _ in
                    self?.isLoadingSubject.send(false)
                },
                receiveCancel: { [weak self] in
                    self?.isLoadingSubject.send(false)
                }
            )
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    /// Handles PSD2-compliant biometric authentication
    /// Requirement: Biometric Authentication
    private func loginWithBiometrics() -> AnyPublisher<Void, AuthenticationError> {
        guard biometricManager.isAvailable else {
            return Fail(error: AuthenticationError.biometricFailed).eraseToAnyPublisher()
        }
        
        isLoadingSubject.send(true)
        
        return authService.loginWithBiometrics()
            .handleEvents(
                receiveSubscription: { [weak self] _ in
                    self?.isLoadingSubject.send(true)
                },
                receiveCompletion: { [weak self] _ in
                    self?.isLoadingSubject.send(false)
                },
                receiveCancel: { [weak self] in
                    self?.isLoadingSubject.send(false)
                }
            )
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    /// Checks and updates biometric authentication availability
    /// Requirement: Platform-specific secure storage
    private func checkBiometricAvailability() {
        let isAvailable = biometricManager.checkBiometricAvailability()
        isBiometricAvailableSubject.send(isAvailable)
    }
    
    /// Sets up observer for authentication state changes
    private func setupAuthStateObserver() {
        authService.authStatePublisher
            .sink { [weak self] state in
                switch state {
                case .authenticated:
                    self?.loginSuccessSubject.send()
                case .unauthenticated:
                    self?.errorMessageSubject.send(.unauthorized)
                case .refreshing:
                    self?.isLoadingSubject.send(true)
                case .biometricInProgress:
                    self?.isLoadingSubject.send(true)
                }
            }
            .store(in: &cancellables)
    }
}