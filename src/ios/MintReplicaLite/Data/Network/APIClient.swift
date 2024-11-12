//
// APIClient.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Configure SSL certificate pinning in Info.plist
// 2. Review and adjust request timeout values for production environment
// 3. Configure background session identifier in project capabilities
// 4. Verify URLSession configuration with security team

import Foundation // iOS 14.0+
import Combine // iOS 14.0+

// Import relative to current file location
import "./APIError"
import "./APIRouter"
import "./NetworkMonitor"

/// A comprehensive networking client implementing secure API communication
/// Implements Transport Security requirement from Section 2.4 Security Architecture
@objc final class APIClient {
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = APIClient()
    
    /// URLSession configured with secure settings
    private let session: URLSession
    
    /// Concurrent queue for handling requests
    private let requestQueue: DispatchQueue
    
    /// Request timeout interval in seconds
    private let timeout: TimeInterval
    
    /// Maximum number of retry attempts
    private let maxRetries: Int
    
    /// Publisher indicating if a request is in progress
    private let isRequestInProgress: CurrentValueSubject<Bool, Never>
    
    // MARK: - Initialization
    
    private init() {
        // Configure URLSession with secure settings
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv13
        configuration.httpAdditionalHeaders = [
            "X-Client-Version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
            "X-Platform": "iOS"
        ]
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: configuration)
        self.requestQueue = DispatchQueue(label: "com.mintreplicalite.apiclient",
                                        qos: .userInitiated,
                                        attributes: .concurrent)
        self.timeout = 30.0
        self.maxRetries = 3
        self.isRequestInProgress = CurrentValueSubject<Bool, Never>(false)
    }
    
    // MARK: - Public Methods
    
    /// Performs a type-safe API request with automatic retrying
    /// Implements Client Security requirement from Section 2.4 Security Architecture
    func request<T: Decodable>(_ endpoint: APIRouter, responseType: T.Type) -> AnyPublisher<T, APIError> {
        guard NetworkMonitor.shared.isConnected.value else {
            return Fail(error: APIError.noInternet(nil)).eraseToAnyPublisher()
        }
        
        return Future { [weak self] promise in
            guard let self = self else { return }
            
            do {
                var urlRequest = try endpoint.asURLRequest()
                urlRequest.timeoutInterval = self.timeout
                
                self.performRequest(urlRequest, attempt: 1) { result in
                    switch result {
                    case .success(let data):
                        do {
                            let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .iso8601
                            decoder.keyDecodingStrategy = .convertFromSnakeCase
                            
                            let response = try decoder.decode(T.self, from: data)
                            promise(.success(response))
                        } catch {
                            let apiError = APIError.decodingError(error)
                            apiError.log()
                            promise(.failure(apiError))
                        }
                    case .failure(let error):
                        error.log()
                        promise(.failure(error))
                    }
                }
            } catch {
                let apiError = APIError.invalidURL("Failed to create request")
                apiError.log()
                promise(.failure(apiError))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Uploads data with progress tracking
    /// Implements Real-time Data Flows requirement from Section 3.3.3
    func upload(data: Data, endpoint: APIRouter) -> AnyPublisher<Progress, APIError> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            
            do {
                var urlRequest = try endpoint.asURLRequest()
                urlRequest.httpBody = data
                
                let uploadTask = self.session.uploadTask(with: urlRequest, from: data) { data, response, error in
                    if let error = error {
                        promise(.failure(.unknown(error)))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        promise(.failure(.invalidResponse(0)))
                        return
                    }
                    
                    do {
                        try self.validateResponse(httpResponse)
                        let progress = Progress(totalUnitCount: Int64(data.count))
                        progress.completedUnitCount = Int64(data.count)
                        promise(.success(progress))
                    } catch let error as APIError {
                        promise(.failure(error))
                    } catch {
                        promise(.failure(.unknown(error)))
                    }
                }
                
                uploadTask.resume()
            } catch {
                promise(.failure(.invalidURL("Failed to create upload request")))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Downloads data with progress tracking
    /// Implements Real-time Data Flows requirement from Section 3.3.3
    func download(endpoint: APIRouter, destination: URL) -> AnyPublisher<Progress, APIError> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            
            do {
                let urlRequest = try endpoint.asURLRequest()
                
                let downloadTask = self.session.downloadTask(with: urlRequest) { tempURL, response, error in
                    if let error = error {
                        promise(.failure(.unknown(error)))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        promise(.failure(.invalidResponse(0)))
                        return
                    }
                    
                    do {
                        try self.validateResponse(httpResponse)
                        
                        guard let tempURL = tempURL else {
                            promise(.failure(.invalidResponse(httpResponse.statusCode)))
                            return
                        }
                        
                        try FileManager.default.moveItem(at: tempURL, to: destination)
                        
                        let progress = Progress(totalUnitCount: 100)
                        progress.completedUnitCount = 100
                        promise(.success(progress))
                    } catch let error as APIError {
                        promise(.failure(error))
                    } catch {
                        promise(.failure(.unknown(error)))
                    }
                }
                
                downloadTask.resume()
            } catch {
                promise(.failure(.invalidURL("Failed to create download request")))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

// MARK: - Private Extensions

private extension APIClient {
    /// Validates HTTP response status codes and headers
    /// Implements Transport Security requirement from Section 2.4
    func validateResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap(Double.init)
            throw APIError.rateLimited(retryAfter: retryAfter)
        case 500...599:
            throw APIError.serverError(response.statusCode, nil)
        default:
            throw APIError.invalidResponse(response.statusCode)
        }
    }
    
    /// Determines if request should be retried
    /// Implements Client Security requirement from Section 2.4
    func shouldRetry(_ error: APIError, attempt: Int) -> Bool {
        guard attempt < maxRetries,
              error.isRetryable,
              NetworkMonitor.shared.isConnected.value else {
            return false
        }
        
        // Apply exponential backoff
        let delay = TimeInterval(pow(2.0, Double(attempt))) * 0.5
        Thread.sleep(forTimeInterval: delay)
        
        return true
    }
    
    /// Performs the actual request with retry logic
    func performRequest(_ request: URLRequest, attempt: Int, completion: @escaping (Result<Data, APIError>) -> Void) {
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                let apiError = APIError.unknown(error)
                
                if self.shouldRetry(apiError, attempt: attempt) {
                    self.performRequest(request, attempt: attempt + 1, completion: completion)
                    return
                }
                
                completion(.failure(apiError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse(0)))
                return
            }
            
            do {
                try self.validateResponse(httpResponse)
                
                guard let responseData = data else {
                    completion(.failure(.invalidResponse(httpResponse.statusCode)))
                    return
                }
                
                completion(.success(responseData))
            } catch let error as APIError {
                if self.shouldRetry(error, attempt: attempt) {
                    self.performRequest(request, attempt: attempt + 1, completion: completion)
                    return
                }
                
                completion(.failure(error))
            } catch {
                completion(.failure(.unknown(error)))
            }
        }.resume()
    }
}