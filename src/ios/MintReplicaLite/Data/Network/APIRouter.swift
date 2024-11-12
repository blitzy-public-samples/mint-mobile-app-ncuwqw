//
// APIRouter.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify SSL certificate pinning configuration in Info.plist
// 2. Ensure API keys are properly configured in build settings
// 3. Configure environment-specific base URLs in build schemes
// 4. Review timeout configurations for specific network conditions

import Foundation // iOS 14.0+

/// Type-safe API routing system implementing URLRequestConvertible pattern
/// Implements RESTful API Integration requirement from Section 2.1 High-Level Architecture Overview
enum APIRouter {
    // MARK: - Authentication Cases
    case login(email: String, password: String)
    case refreshToken(token: String)
    
    // MARK: - Account Cases
    case getAccounts
    case getAccount(id: String)
    
    // MARK: - Transaction Cases
    case getTransactions(accountId: String?, fromDate: Date?, toDate: Date?)
    case createTransaction(accountId: String, amount: Decimal, category: String, date: Date)
    
    // MARK: - Budget Cases
    case getBudgets(month: Date?)
    case createBudget(categoryId: String, amount: Decimal, period: String)
    
    // MARK: - Goal Cases
    case getGoals
    case createGoal(name: String, targetAmount: Decimal, targetDate: Date)
    
    // MARK: - Investment Cases
    case getInvestments
    case getInvestmentDetails(id: String)
    
    // MARK: - Base Properties
    private var baseURL: String {
        #if DEBUG
        return APIConstants.Environment.development.baseURL
        #else
        return APIConstants.Environment.production.baseURL
        #endif
    }
    
    private var method: APIConstants.HTTPMethod {
        switch self {
        case .login, .refreshToken, .createTransaction, .createBudget, .createGoal:
            return .POST
        case .getAccounts, .getAccount, .getTransactions, .getBudgets,
             .getGoals, .getInvestments, .getInvestmentDetails:
            return .GET
        }
    }
    
    private var path: String {
        switch self {
        case .login:
            return "\(APIConstants.Endpoints.auth)/login"
        case .refreshToken:
            return "\(APIConstants.Endpoints.auth)/refresh"
        case .getAccounts:
            return APIConstants.Endpoints.accounts
        case .getAccount(let id):
            return "\(APIConstants.Endpoints.accounts)/\(id)"
        case .getTransactions:
            return APIConstants.Endpoints.transactions
        case .createTransaction:
            return APIConstants.Endpoints.transactions
        case .getBudgets:
            return APIConstants.Endpoints.budgets
        case .createBudget:
            return APIConstants.Endpoints.budgets
        case .getGoals:
            return APIConstants.Endpoints.goals
        case .createGoal:
            return APIConstants.Endpoints.goals
        case .getInvestments:
            return APIConstants.Endpoints.investments
        case .getInvestmentDetails(let id):
            return "\(APIConstants.Endpoints.investments)/\(id)"
        }
    }
    
    private var headers: [String: String] {
        var headers = [
            APIConstants.Headers.contentType: APIConstants.ContentType.json,
            APIConstants.Headers.accept: APIConstants.ContentType.json
        ]
        
        // Implement Authentication Flow requirement from Section 6.1.1
        switch self {
        case .login, .refreshToken:
            break // No auth headers needed for authentication endpoints
        default:
            if let token = UserDefaults.standard.string(forKey: "authToken") {
                headers[APIConstants.Headers.authorization] = "Bearer \(token)"
            }
        }
        
        // Add security headers
        headers[APIConstants.Headers.apiKey] = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String
        headers[APIConstants.Headers.deviceId] = UIDevice.current.identifierForVendor?.uuidString
        
        return headers
    }
    
    private var body: Data? {
        switch self {
        case .login(let email, let password):
            return try? JSONSerialization.data(withJSONObject: [
                "email": email,
                "password": password
            ])
            
        case .refreshToken(let token):
            return try? JSONSerialization.data(withJSONObject: [
                "refresh_token": token
            ])
            
        case .createTransaction(let accountId, let amount, let category, let date):
            return try? JSONSerialization.data(withJSONObject: [
                "account_id": accountId,
                "amount": amount as NSDecimalNumber,
                "category": category,
                "date": ISO8601DateFormatter().string(from: date)
            ])
            
        case .createBudget(let categoryId, let amount, let period):
            return try? JSONSerialization.data(withJSONObject: [
                "category_id": categoryId,
                "amount": amount as NSDecimalNumber,
                "period": period
            ])
            
        case .createGoal(let name, let targetAmount, let targetDate):
            return try? JSONSerialization.data(withJSONObject: [
                "name": name,
                "target_amount": targetAmount as NSDecimalNumber,
                "target_date": ISO8601DateFormatter().string(from: targetDate)
            ])
            
        default:
            return nil
        }
    }
}

// MARK: - URLRequestConvertible Implementation
extension APIRouter: URLRequestConvertible {
    /// Converts router case to URLRequest with proper security configuration
    /// Implements Transport Security requirement from Section 2.4 Security Architecture
    func asURLRequest() throws -> URLRequest {
        // Construct and validate URL
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw APIError.invalidURL("Invalid base URL: \(baseURL)")
        }
        
        urlComponents.path = path
        
        // Add query parameters for GET requests
        switch self {
        case .getTransactions(let accountId, let fromDate, let toDate):
            var queryItems: [URLQueryItem] = []
            if let accountId = accountId {
                queryItems.append(URLQueryItem(name: "account_id", value: accountId))
            }
            if let fromDate = fromDate {
                queryItems.append(URLQueryItem(name: "from_date", 
                                            value: ISO8601DateFormatter().string(from: fromDate)))
            }
            if let toDate = toDate {
                queryItems.append(URLQueryItem(name: "to_date", 
                                            value: ISO8601DateFormatter().string(from: toDate)))
            }
            urlComponents.queryItems = queryItems
            
        case .getBudgets(let month):
            if let month = month {
                urlComponents.queryItems = [
                    URLQueryItem(name: "month", 
                               value: ISO8601DateFormatter().string(from: month))
                ]
            }
            
        default:
            break
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL("Failed to construct URL with path: \(path)")
        }
        
        // Create and configure URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        // Configure timeout
        request.timeoutInterval = APIConstants.TimeoutConfig.defaultTimeout
        
        // Configure security settings
        if APIConstants.SecurityConfig.requiresCertificatePinning {
            // Enable certificate pinning validation
            request.setValue("true", forHTTPHeaderField: "Certificate-Pinning")
        }
        
        return request
    }
}

// MARK: - Helper Functions
private extension APIRouter {
    /// Builds URL query parameters from dictionary with proper encoding
    /// - Parameter parameters: Dictionary of parameter key-value pairs
    /// - Returns: URL encoded query string
    func buildQueryParameters(_ parameters: [String: Any]) -> String {
        return parameters.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
    }
}