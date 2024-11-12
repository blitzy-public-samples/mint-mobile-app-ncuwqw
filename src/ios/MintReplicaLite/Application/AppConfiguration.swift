//
// AppConfiguration.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify environment configuration matches build schemes in Xcode project
// 2. Ensure proper SSL certificates are configured for each environment
// 3. Review and adjust timeout values based on production metrics
// 4. Configure proper keychain access groups if app extension support is needed

// Foundation framework - iOS 14.0+
import Foundation

// Relative imports from project modules
import "../Common/Constants/APIConstants"
import "../Common/Constants/AppConstants"

// Global environment configuration
private let CurrentEnvironment: APIConstants.Environment = .production

/// AppConfiguration: Singleton class managing application-wide configuration settings
/// Implements Client Applications Configuration requirement from Section 1.1 System Overview
final class AppConfiguration {
    
    // MARK: - Properties
    
    private static var instance: AppConfiguration?
    private static let lock = DispatchQueue(label: "com.mintreplicaLite.appConfiguration")
    
    private(set) var environment: APIConstants.Environment
    private(set) var isDebugMode: Bool
    private(set) var sessionTimeout: TimeInterval
    private(set) var maxRetryAttempts: Int
    private(set) var isBiometricEnabled: Bool
    private(set) var cacheExpiry: TimeInterval
    private(set) var maxCacheSize: Int
    
    // MARK: - Singleton Access
    
    /// Thread-safe singleton instance accessor
    /// Implements System Architecture requirement from Section 2.1
    static var shared: AppConfiguration {
        if instance == nil {
            lock.sync {
                if instance == nil {
                    instance = AppConfiguration()
                }
            }
        }
        return instance!
    }
    
    // MARK: - Initialization
    
    /// Private initializer implementing singleton pattern
    /// Implements Security Infrastructure requirement from Section 1.1
    private init() {
        // Initialize with default environment
        self.environment = CurrentEnvironment
        
        // Configure debug mode based on build configuration
        #if DEBUG
        self.isDebugMode = true
        #else
        self.isDebugMode = false
        #endif
        
        // Initialize security settings
        self.sessionTimeout = AppConstants.Security.sessionTimeout
        self.maxRetryAttempts = AppConstants.Sync.maxSyncRetries
        self.isBiometricEnabled = AppConstants.Security.biometricAuthEnabled
        
        // Initialize cache settings
        self.cacheExpiry = AppConstants.Cache.defaultCacheExpiry
        self.maxCacheSize = AppConstants.Cache.maxCacheSize
    }
    
    // MARK: - Configuration Methods
    
    /// Configures the application with specific environment settings
    /// Implements System Architecture requirement from Section 2.1
    func configure(environment: APIConstants.Environment) {
        lock.sync {
            self.environment = environment
            
            // Update timeout configuration based on environment
            switch environment {
            case .development:
                sessionTimeout = TimeInterval(AppConstants.Security.sessionTimeout * 2) // Extended for development
            case .staging:
                sessionTimeout = AppConstants.Security.sessionTimeout
            case .production:
                sessionTimeout = AppConstants.Security.sessionTimeout
            }
            
            // Configure security settings
            maxRetryAttempts = APIConstants.SecurityConfig.maxRetryAttempts
            
            // Update cache configuration
            if environment == .development {
                cacheExpiry = AppConstants.Cache.defaultCacheExpiry * 2 // Extended for development
                maxCacheSize = AppConstants.Cache.maxCacheSize * 2
            } else {
                cacheExpiry = AppConstants.Cache.defaultCacheExpiry
                maxCacheSize = AppConstants.Cache.maxCacheSize
            }
        }
    }
    
    /// Retrieves the base URL for API requests based on current environment
    /// Implements System Architecture requirement from Section 2.1
    func getAPIBaseURL() -> String {
        return environment.baseURL
    }
    
    /// Toggles debug mode for development purposes
    /// Implements Security Infrastructure requirement from Section 1.1
    func toggleDebugMode(_ enabled: Bool) {
        lock.sync {
            isDebugMode = enabled
            
            // Adjust security parameters for debugging
            if enabled {
                // Relaxed security settings for debugging
                sessionTimeout *= 2
                maxRetryAttempts += 2
            } else {
                // Reset to production security settings
                sessionTimeout = AppConstants.Security.sessionTimeout
                maxRetryAttempts = APIConstants.SecurityConfig.maxRetryAttempts
            }
            
            // Configure certificate pinning
            let certificatePinningEnabled = !enabled && APIConstants.SecurityConfig.requiresCertificatePinning
            
            // Additional debug-specific configurations would go here
            #if DEBUG
            print("[AppConfiguration] Debug mode: \(enabled ? "enabled" : "disabled")")
            print("[AppConfiguration] Certificate pinning: \(certificatePinningEnabled ? "enabled" : "disabled")")
            #endif
        }
    }
}