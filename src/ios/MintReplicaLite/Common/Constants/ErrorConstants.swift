//
// ErrorConstants.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Ensure error messages comply with your organization's localization guidelines
// 2. Review error codes with security team to ensure they don't expose sensitive information
// 3. Verify error messages with UX team for user-friendliness
// 4. Configure proper error tracking/logging system integration

import Foundation // version: iOS 14.0+

// Global error domain for the application
// Requirement: Client Applications - iOS native application error handling implementation
let ErrorDomain: String = "com.mintreplicaLite.error"

/// Root enumeration containing all error-related constants and types
/// Requirement: Error Handling - Generic error messages and proper error handling
enum ErrorConstants {
    
    /// Network-related error types for handling connectivity and API communication issues
    enum NetworkError: Int {
        case noInternet = 1001
        case timeout = 1002
        case serverUnreachable = 1003
        case invalidResponse = 1004
        case unauthorized = 1005
        case forbidden = 1006
        
        // Static properties for network error handling configuration
        static let defaultErrorMessage = "An unexpected error occurred. Please try again."
        static let maxRetryAttempts = 3
        static let requestTimeout: TimeInterval = 30.0
    }
    
    /// Authentication-related error types for handling user authentication and session management
    enum AuthenticationError: Int {
        case invalidCredentials = 2001
        case sessionExpired = 2002
        case biometricsFailed = 2003
        case tooManyAttempts = 2004
        case accountLocked = 2005
        
        // Static properties for authentication configuration
        static let maxLoginAttempts = 3
        static let lockoutDuration: TimeInterval = 300.0 // 5 minutes in seconds
    }
    
    /// Data handling and persistence error types for managing local and remote data operations
    enum DataError: Int {
        case invalidData = 3001
        case saveFailed = 3002
        case loadFailed = 3003
        case syncFailed = 3004
        case deleteFailed = 3005
        case notFound = 3006
        
        // Static properties for data operation configuration
        static let syncRetryInterval: TimeInterval = 60.0
        static let maxSyncRetries = 3
    }
    
    /// Input validation error types for handling user input validation across the application
    enum ValidationError: Int {
        case invalidAmount = 4001
        case invalidDate = 4002
        case invalidCategory = 4003
        case exceedsBudget = 4004
        case invalidGoal = 4005
    }
    
    /// User-facing error messages following security best practices for generic error communication
    /// Requirement: Security Controls - Error handling and input validation for client-side security
    enum LocalizedMessages {
        static let networkError = "Unable to connect to the server. Please check your internet connection."
        static let authenticationError = "Unable to authenticate. Please check your credentials and try again."
        static let sessionExpired = "Your session has expired. Please log in again."
        static let dataError = "Unable to process your request. Please try again."
        static let syncError = "Unable to sync your data. Please try again later."
        static let validationError = "Please check your input and try again."
    }
}

// Extension to provide error code ranges for different categories
extension ErrorConstants {
    struct ErrorCodeRanges {
        static let networkErrorRange = 1001...1999
        static let authErrorRange = 2001...2999
        static let dataErrorRange = 3001...3999
        static let validationErrorRange = 4001...4999
    }
}

// Extension to provide helper methods for error handling
extension ErrorConstants {
    /// Determines if an error code belongs to a specific error category
    /// - Parameter code: The error code to check
    /// - Returns: The error category as a string
    static func getErrorCategory(for code: Int) -> String {
        switch code {
        case ErrorCodeRanges.networkErrorRange:
            return "Network Error"
        case ErrorCodeRanges.authErrorRange:
            return "Authentication Error"
        case ErrorCodeRanges.dataErrorRange:
            return "Data Error"
        case ErrorCodeRanges.validationErrorRange:
            return "Validation Error"
        default:
            return "Unknown Error"
        }
    }
    
    /// Returns a user-friendly message for a given error code
    /// - Parameter code: The error code
    /// - Returns: A localized, user-friendly error message
    static func getLocalizedMessage(for code: Int) -> String {
        switch code {
        case ErrorCodeRanges.networkErrorRange:
            return LocalizedMessages.networkError
        case ErrorCodeRanges.authErrorRange:
            return LocalizedMessages.authenticationError
        case ErrorCodeRanges.dataErrorRange:
            return LocalizedMessages.dataError
        case ErrorCodeRanges.validationErrorRange:
            return LocalizedMessages.validationError
        default:
            return NetworkError.defaultErrorMessage
        }
    }
}