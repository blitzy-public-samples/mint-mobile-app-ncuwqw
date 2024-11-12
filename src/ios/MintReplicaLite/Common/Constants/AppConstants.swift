//
// AppConstants.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify bundle identifier matches provisioning profile configuration
// 2. Configure proper build schemes for version and build number management
// 3. Review and adjust timeout values based on user behavior analytics
// 4. Validate financial limits align with business requirements
// 5. Configure push notification topics in Apple Developer Portal

// Foundation framework - iOS 14.0+
import Foundation
import Common.Constants.APIConstants

// Global application configuration values
let AppBundleIdentifier: String = "com.mintreplicaLite"
let AppVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
let AppBuild: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

/// Root enumeration containing all application-wide constant definitions organized by functional domains
/// Implements Client Applications Configuration requirement from Section 1.1 System Overview
enum AppConstants {
    
    /// UI-related constants for consistent visual styling and behavior across the app
    /// Implements Client Applications Configuration requirement from Section 1.1
    enum UI {
        static let defaultCornerRadius: CGFloat = 8.0
        static let defaultPadding: CGFloat = 16.0
        static let defaultAnimationDuration: CGFloat = 0.3
        static let maxTableViewRows: Int = 100
    }
    
    /// Security-related constants for authentication and data protection
    /// Implements Security Infrastructure requirement from Section 1.1
    enum Security {
        static let sessionTimeout: TimeInterval = 1800.0 // 30 minutes
        static let maxLoginAttempts: Int = 3
        static let biometricAuthEnabled: Bool = true
        static let keychainServiceName: String = "com.mintreplicaLite.keychain"
    }
    
    /// Financial data formatting and business rule constants
    /// Implements Financial Data Management requirement from Section 1.2
    enum Financial {
        static let defaultCurrency: String = "USD"
        static let maxTransactionHistory: Int = 1000
        static let maxBudgetCategories: Int = 20
        static let maxGoals: Int = 10
    }
    
    /// Caching configuration for optimizing data storage and retrieval
    /// Implements Client Applications Configuration requirement from Section 1.1
    enum Cache {
        static let defaultCacheExpiry: TimeInterval = 3600.0 // 1 hour
        static let maxCacheSize: Int = 50 * 1024 * 1024 // 50 MB
    }
    
    /// Data synchronization settings for backend communication
    /// Implements Client Applications Configuration requirement from Section 1.1
    enum Sync {
        static let syncInterval: TimeInterval = 300.0 // 5 minutes
        static let maxSyncRetries: Int = 3
        static let syncTimeout: TimeInterval = 60.0
    }
    
    /// Push notification configuration and topic definitions
    /// Implements Client Applications Configuration requirement from Section 1.1
    enum Notifications {
        static let budgetAlertTopic: String = "budget_alerts"
        static let goalAlertTopic: String = "goal_alerts"
        static let transactionAlertTopic: String = "transaction_alerts"
    }
}