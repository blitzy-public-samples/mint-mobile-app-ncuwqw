//
// BiometricAuthManager.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify biometric authentication entitlements are enabled in Xcode project
// 2. Add NSFaceIDUsageDescription key to Info.plist with appropriate message
// 3. Test biometric authentication on physical devices with Face ID/Touch ID
// 4. Review biometric authentication error messages with UX team

import LocalAuthentication // version: iOS 14.0+
import Foundation // version: iOS 14.0+

/// Enum representing available biometric authentication types
/// Requirement: Platform-Specific Security - iOS-specific security measures including biometric authentication
enum BiometricType {
    case none
    case touchID
    case faceID
}

/// Manages biometric authentication functionality with PSD2 compliance
/// Requirement: Biometric Authentication - Implement biometric authentication for secure user access
@objc final class BiometricAuthManager {
    
    // MARK: - Properties
    
    private let context: LAContext
    private(set) var availableBiometricType: BiometricType
    private(set) var isAvailable: Bool
    private let maxAttempts: Int
    
    // MARK: - Singleton
    
    /// Shared instance of BiometricAuthManager
    static let shared = BiometricAuthManager()
    
    // MARK: - Initialization
    
    private init() {
        self.context = LAContext()
        self.maxAttempts = ErrorConstants.AuthenticationError.maxLoginAttempts
        self.availableBiometricType = .none
        self.isAvailable = false
        
        // Initial biometric availability check
        _ = checkBiometricAvailability()
    }
    
    // MARK: - Public Methods
    
    /// Checks if biometric authentication is available on the device
    /// Requirement: Platform-Specific Security - iOS-specific security measures
    func checkBiometricAvailability() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if canEvaluate {
            isAvailable = true
            
            // Determine biometric type
            switch context.biometryType {
            case .touchID:
                availableBiometricType = .touchID
            case .faceID:
                availableBiometricType = .faceID
            default:
                availableBiometricType = .none
            }
        } else {
            isAvailable = false
            availableBiometricType = .none
        }
        
        Logger.shared.log(
            "Biometric availability checked: \(isAvailable), type: \(availableBiometricType)",
            level: .info,
            category: .security
        )
        
        return isAvailable
    }
    
    /// Authenticates user using available biometric method
    /// Requirement: Strong Customer Authentication - Implementation of strong customer authentication methods
    func authenticateUser(reason: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // Verify biometric availability
        guard isAvailable else {
            Logger.shared.log(
                "Biometric authentication failed: not available",
                level: .error,
                category: .security
            )
            completion(.failure(NSError(
                domain: ErrorConstants.ErrorDomain,
                code: ErrorConstants.AuthenticationError.biometricsFailed.rawValue,
                userInfo: [NSLocalizedDescriptionKey: ErrorConstants.LocalizedMessages.authenticationError]
            )))
            return
        }
        
        // Create new context for each authentication attempt
        let context = LAContext()
        
        // Evaluate biometric authentication
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { [weak self] success, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    Logger.shared.log(
                        "Biometric authentication successful",
                        level: .info,
                        category: .security
                    )
                    completion(.success(true))
                } else {
                    let errorCode = (error as? LAError)?.errorCode ?? 0
                    
                    // Handle specific biometric errors
                    let authError: Error
                    switch errorCode {
                    case LAError.authenticationFailed.rawValue:
                        authError = NSError(
                            domain: ErrorConstants.ErrorDomain,
                            code: ErrorConstants.AuthenticationError.biometricsFailed.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: ErrorConstants.LocalizedMessages.authenticationError]
                        )
                    case LAError.userCancel.rawValue:
                        authError = NSError(
                            domain: ErrorConstants.ErrorDomain,
                            code: ErrorConstants.AuthenticationError.biometricsFailed.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: "Authentication cancelled by user"]
                        )
                    case LAError.userFallback.rawValue:
                        authError = NSError(
                            domain: ErrorConstants.ErrorDomain,
                            code: ErrorConstants.AuthenticationError.biometricsFailed.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: "User requested fallback authentication"]
                        )
                    case LAError.biometryNotAvailable.rawValue:
                        authError = NSError(
                            domain: ErrorConstants.ErrorDomain,
                            code: ErrorConstants.AuthenticationError.biometricsFailed.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: "Biometric authentication not available"]
                        )
                    case LAError.biometryNotEnrolled.rawValue:
                        authError = NSError(
                            domain: ErrorConstants.ErrorDomain,
                            code: ErrorConstants.AuthenticationError.biometricsFailed.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: "No biometric authentication enrolled"]
                        )
                    default:
                        authError = error ?? NSError(
                            domain: ErrorConstants.ErrorDomain,
                            code: ErrorConstants.AuthenticationError.biometricsFailed.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: ErrorConstants.LocalizedMessages.authenticationError]
                        )
                    }
                    
                    Logger.shared.log(
                        "Biometric authentication failed: \(authError.localizedDescription)",
                        level: .error,
                        category: .security
                    )
                    completion(.failure(authError))
                }
            }
        }
    }
    
    /// Returns the type of biometric authentication available
    /// Requirement: Platform-Specific Security - iOS-specific security measures
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            Logger.shared.log(
                "No biometric type available",
                level: .info,
                category: .security
            )
            return .none
        }
        
        switch context.biometryType {
        case .touchID:
            Logger.shared.log(
                "Touch ID available",
                level: .info,
                category: .security
            )
            return .touchID
        case .faceID:
            Logger.shared.log(
                "Face ID available",
                level: .info,
                category: .security
            )
            return .faceID
        default:
            Logger.shared.log(
                "No specific biometric type detected",
                level: .info,
                category: .security
            )
            return .none
        }
    }
}