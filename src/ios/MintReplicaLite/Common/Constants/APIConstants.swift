//
// APIConstants.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify SSL certificates are properly configured for certificate pinning
// 2. Ensure API keys are securely stored in configuration files
// 3. Configure proper environment variables for different build schemes
// 4. Update rate limiting values based on infrastructure capacity

// Foundation framework - iOS 14.0+
import Foundation

/// Root enumeration containing all API-related constant definitions for secure backend communication
/// Implements RESTful API Integration requirement from Section 2.1 High-Level Architecture Overview
enum APIConstants {
    
    /// API environment configuration with associated base URLs
    enum Environment {
        case development
        case staging
        case production
        
        /// Base URL for the selected environment
        /// Implements Transport Security requirement from Section 6.3.4 Platform-Specific Security
        var baseURL: String {
            switch self {
            case .development:
                return "https://api-dev.mintreplica.com"
            case .staging:
                return "https://api-staging.mintreplica.com"
            case .production:
                return "https://api.mintreplica.com"
            }
        }
    }
    
    /// API endpoint paths following RESTful conventions
    /// Implements RESTful API Integration requirement from Section 2.1
    enum Endpoints {
        static let auth = "/api/v1/auth"
        static let accounts = "/api/v1/accounts"
        static let transactions = "/api/v1/transactions"
        static let budgets = "/api/v1/budgets"
        static let goals = "/api/v1/goals"
        static let investments = "/api/v1/investments"
    }
    
    /// HTTP header constants for secure API communication
    /// Implements Secure Authentication requirement from Section 6.1.1 Authentication Flow
    enum Headers {
        static let authorization = "Authorization"
        static let contentType = "Content-Type"
        static let accept = "Accept"
        static let apiKey = "X-API-Key"
        static let deviceId = "X-Device-ID"
        static let appVersion = "X-App-Version"
    }
    
    /// Content type header values for API requests and responses
    /// Implements API Security Standards requirement from Section 6.3.3 Security Controls
    enum ContentType {
        static let json = "application/json"
        static let multipart = "multipart/form-data"
    }
    
    /// HTTP method constants for API requests
    /// Implements RESTful API Integration requirement from Section 2.1
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        case PATCH = "PATCH"
    }
    
    /// Network timeout configurations in seconds
    /// Implements API Security Standards requirement from Section 6.3.3
    enum TimeoutConfig {
        static let defaultTimeout: TimeInterval = 30.0
        static let uploadTimeout: TimeInterval = 60.0
        static let downloadTimeout: TimeInterval = 60.0
    }
    
    /// API security configuration constants
    /// Implements Transport Security requirement from Section 6.3.4 and
    /// API Security Standards requirement from Section 6.3.3
    enum SecurityConfig {
        static let requiresCertificatePinning: Bool = true
        static let maxRetryAttempts: Int = 3
        static let tokenRefreshThreshold: TimeInterval = 300.0 // 5 minutes
        static let maxRequestsPerMinute: Int = 100
    }
}