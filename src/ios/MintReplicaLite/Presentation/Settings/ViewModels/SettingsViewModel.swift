//
// SettingsViewModel.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify biometric authentication entitlements are enabled in project settings
// 2. Add NSFaceIDUsageDescription key to Info.plist with appropriate message
// 3. Configure notification permissions in project capabilities
// 4. Review error messages with UX team for localization
//
// Third-party Dependencies:
// - Foundation (iOS 14.0+)
// - Combine (iOS 14.0+)

import Foundation
import Combine

// Relative imports
import Common.Protocols.ViewModelType
import Common.Utils.BiometricAuthManager
import Common.Utils.KeychainManager

/// Error types specific to settings operations
/// Requirements addressed:
/// - Client Security (2.4): Proper error handling for security operations
enum SettingsViewModelError: Error {
    case biometricNotAvailable
    case biometricAuthFailed
    case notificationPermissionDenied
    case logoutFailed
}

/// ViewModel responsible for managing settings screen business logic
/// Requirements addressed:
/// - Security Infrastructure (1.1): Platform-specific secure storage and authentication
/// - Client Security (2.4): Biometric authentication and secure storage configuration
/// - Platform-Specific Security (6.3.4): iOS-specific security measures
final class SettingsViewModel {
    
    // MARK: - Properties
    
    private let biometricAuthManager: BiometricAuthManager
    private let keychainManager: KeychainManager
    
    // Publishers for settings state
    private let isBiometricEnabled = CurrentValueSubject<Bool, Never>(false)
    private let isNotificationsEnabled = CurrentValueSubject<Bool, Never>(false)
    private let logoutTrigger = PassthroughSubject<Void, Never>()
    private let errorSubject = CurrentValueSubject<SettingsViewModelError?, Never>(nil)
    
    // Store subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        self.biometricAuthManager = .shared
        self.keychainManager = .shared
        
        // Load current settings state
        loadInitialState()
    }
    
    // MARK: - Private Methods
    
    private func loadInitialState() {
        // Check biometric availability and current state
        let biometricAvailable = biometricAuthManager.checkBiometricAvailability()
        isBiometricEnabled.send(biometricAvailable && UserDefaults.standard.bool(forKey: "biometricAuthEnabled"))
        
        // Check notification permission status
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isNotificationsEnabled.send(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Toggles PSD2-compliant biometric authentication setting
    /// Requirements addressed:
    /// - Client Security (2.4): PSD2-compliant biometric authentication
    func toggleBiometricAuth(enabled: Bool) -> AnyPublisher<Bool, Error> {
        guard biometricAuthManager.isAvailable else {
            return Fail(error: SettingsViewModelError.biometricNotAvailable)
                .eraseToAnyPublisher()
        }
        
        if enabled {
            return Future<Bool, Error> { [weak self] promise in
                self?.biometricAuthManager.authenticateUser(
                    reason: "Enable biometric authentication for secure access"
                ) { result in
                    switch result {
                    case .success:
                        UserDefaults.standard.set(true, forKey: "biometricAuthEnabled")
                        promise(.success(true))
                    case .failure:
                        promise(.failure(SettingsViewModelError.biometricAuthFailed))
                    }
                }
            }
            .eraseToAnyPublisher()
        } else {
            UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")
            return Just(false)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    /// Toggles push notification settings with secure storage
    /// Requirements addressed:
    /// - Platform-Specific Security (6.3.4): iOS notification handling
    func toggleNotifications(enabled: Bool) -> AnyPublisher<Bool, Error> {
        if enabled {
            return Future<Bool, Error> { promise in
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                ) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                            promise(.success(true))
                        } else {
                            promise(.failure(SettingsViewModelError.notificationPermissionDenied))
                        }
                    }
                }
            }
            .eraseToAnyPublisher()
        } else {
            UserDefaults.standard.set(false, forKey: "notificationsEnabled")
            return Just(false)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    /// Handles secure user logout process
    /// Requirements addressed:
    /// - Security Infrastructure (1.1): Secure data cleanup
    /// - Platform-Specific Security (6.3.4): iOS Keychain management
    func logout() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else { return }
            
            // Clear keychain data
            switch self.keychainManager.clear() {
            case .success:
                // Reset user preferences
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                
                // Clear biometric and notification settings
                self.isBiometricEnabled.send(false)
                self.isNotificationsEnabled.send(false)
                
                promise(.success(()))
            case .failure:
                promise(.failure(SettingsViewModelError.logoutFailed))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - ViewModelType Conformance

extension SettingsViewModel: ViewModelType {
    struct Input {
        let biometricToggle: AnyPublisher<Bool, Never>
        let notificationToggle: AnyPublisher<Bool, Never>
        let logoutTap: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let isBiometricEnabled: AnyPublisher<Bool, Never>
        let isNotificationsEnabled: AnyPublisher<Bool, Never>
        let error: AnyPublisher<SettingsViewModelError?, Never>
        let didLogout: AnyPublisher<Void, Never>
    }
    
    /// Transforms view inputs into outputs using Combine operators
    /// Requirements addressed:
    /// - Client Security (2.4): Secure settings management
    func transform(_ input: Input) -> Output {
        // Handle biometric authentication toggle
        input.biometricToggle
            .flatMap { [weak self] enabled -> AnyPublisher<Bool, Error> in
                guard let self = self else {
                    return Fail(error: SettingsViewModelError.biometricAuthFailed)
                        .eraseToAnyPublisher()
                }
                return self.toggleBiometricAuth(enabled: enabled)
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error as? SettingsViewModelError ?? .biometricAuthFailed)
                    }
                },
                receiveValue: { [weak self] enabled in
                    self?.isBiometricEnabled.send(enabled)
                }
            )
            .store(in: &cancellables)
        
        // Handle notification permission toggle
        input.notificationToggle
            .flatMap { [weak self] enabled -> AnyPublisher<Bool, Error> in
                guard let self = self else {
                    return Fail(error: SettingsViewModelError.notificationPermissionDenied)
                        .eraseToAnyPublisher()
                }
                return self.toggleNotifications(enabled: enabled)
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error as? SettingsViewModelError ?? .notificationPermissionDenied)
                    }
                },
                receiveValue: { [weak self] enabled in
                    self?.isNotificationsEnabled.send(enabled)
                }
            )
            .store(in: &cancellables)
        
        // Handle logout action
        input.logoutTap
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: SettingsViewModelError.logoutFailed)
                        .eraseToAnyPublisher()
                }
                return self.logout()
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error as? SettingsViewModelError ?? .logoutFailed)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.logoutTrigger.send()
                }
            )
            .store(in: &cancellables)
        
        return Output(
            isBiometricEnabled: isBiometricEnabled.eraseToAnyPublisher(),
            isNotificationsEnabled: isNotificationsEnabled.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            didLogout: logoutTrigger.eraseToAnyPublisher()
        )
    }
}