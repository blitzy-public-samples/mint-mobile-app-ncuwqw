//
// APIError.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Review error messages with security team to ensure compliance with OWASP guidelines
// 2. Verify error logging configuration in production environment
// 3. Confirm error message localization with UX team

import Foundation // version: iOS 14.0+

/// Comprehensive API error handling system implementing secure error management
/// Requirement: Error Handling - Generic error messages and proper error handling to prevent information disclosure
enum APIError: LocalizedError, CustomStringConvertible {
    // MARK: - Error Cases
    
    case noInternet(Error?)
    case requestTimeout(TimeInterval)
    case invalidURL(String)
    case invalidResponse(Int)
    case decodingError(Error)
    case serverError(Int, Data?)
    case unauthorized
    case forbidden
    case notFound
    case rateLimited(retryAfter: TimeInterval?)
    case unknown(Error?)
    
    // MARK: - LocalizedError Conformance
    
    /// Provides a user-friendly localized description of the error
    /// Requirement: Security Controls - Client-side security error handling and validation
    var errorDescription: String {
        switch self {
        case .noInternet:
            return ErrorConstants.LocalizedMessages.networkError
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .invalidURL:
            return ErrorConstants.LocalizedMessages.networkError
        case .invalidResponse:
            return ErrorConstants.LocalizedMessages.networkError
        case .decodingError:
            return ErrorConstants.LocalizedMessages.networkError
        case .serverError:
            return ErrorConstants.LocalizedMessages.networkError
        case .unauthorized:
            return ErrorConstants.LocalizedMessages.authenticationError
        case .forbidden:
            return ErrorConstants.LocalizedMessages.authenticationError
        case .notFound:
            return ErrorConstants.LocalizedMessages.networkError
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .unknown:
            return ErrorConstants.NetworkError.defaultErrorMessage
        }
    }
    
    // MARK: - CustomStringConvertible Conformance
    
    /// Provides a detailed description for logging purposes
    /// Requirement: Transport Security - Network layer security error handling
    var description: String {
        switch self {
        case .noInternet(let error):
            return "Network connectivity error: \(error?.localizedDescription ?? "Unknown")"
        case .requestTimeout(let timeout):
            return "Request timed out after \(timeout) seconds"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse(let statusCode):
            return "Invalid response with status code: \(statusCode)"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        case .serverError(let statusCode, _):
            return "Server error with status code: \(statusCode)"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimited(let retryAfter):
            return "Rate limited - retry after: \(retryAfter ?? 0) seconds"
        case .unknown(let error):
            return "Unknown error: \(error?.localizedDescription ?? "No details available")"
        }
    }
    
    // MARK: - Additional Properties
    
    /// Returns the HTTP status code associated with the error
    var statusCode: Int {
        switch self {
        case .invalidResponse(let code), .serverError(let code, _):
            return code
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .rateLimited:
            return 429
        default:
            return 0
        }
    }
    
    /// Indicates whether the request can be retried
    var isRetryable: Bool {
        switch self {
        case .noInternet, .requestTimeout, .rateLimited:
            return true
        case .serverError(let code, _):
            return code >= 500 // Server errors are retryable
        case .invalidURL, .invalidResponse, .decodingError,
             .unauthorized, .forbidden, .notFound, .unknown:
            return false
        }
    }
}

// MARK: - APIError Extension

extension APIError {
    /// Logs the API error with appropriate severity and context
    /// Requirement: Security Controls - Client-side security error handling
    func log() {
        let logLevel: LogLevel
        switch self {
        case .serverError, .unknown:
            logLevel = .error
        case .unauthorized, .forbidden:
            logLevel = .warning
        case .noInternet, .requestTimeout, .rateLimited:
            logLevel = .info
        default:
            logLevel = .warning
        }
        
        // Format error message without sensitive data
        let sanitizedMessage = "APIError: \(self.description)"
        
        // Log error with network category
        Logger.shared.log(
            sanitizedMessage,
            level: logLevel,
            category: .network
        )
    }
    
    /// Provides a user-friendly localized error message following security guidelines
    /// Requirement: Error Handling - Generic error messages and proper error handling
    var localizedDescription: String {
        switch self {
        case .unauthorized, .forbidden:
            // Generic message for sensitive errors
            return ErrorConstants.LocalizedMessages.authenticationError
            
        case .noInternet:
            // Safe to show connectivity issues
            return ErrorConstants.LocalizedMessages.networkError
            
        case .requestTimeout(let timeout):
            // Safe to show timeout information
            return "Request timed out after \(Int(timeout)) seconds. Please try again."
            
        case .rateLimited(let retryAfter):
            if let retryAfter = retryAfter {
                return "Please try again in \(Int(ceil(retryAfter))) seconds."
            }
            return "Too many requests. Please try again later."
            
        case .serverError(let code, _):
            // Log the detailed error but return a generic message
            log()
            return "Server error occurred (Code: \(code)). Please try again later."
            
        default:
            // Generic message for all other cases
            return ErrorConstants.NetworkError.defaultErrorMessage
        }
    }
}