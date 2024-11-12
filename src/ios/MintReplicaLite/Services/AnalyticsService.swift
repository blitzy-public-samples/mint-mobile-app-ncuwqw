//
// AnalyticsService.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Configure AWS CloudWatch endpoints in production environment
// 2. Set up Prometheus metrics collection
// 3. Review analytics data retention policies with compliance team
// 4. Verify GDPR compliance for user data collection
// 5. Configure analytics event batching thresholds

import Foundation // iOS 14.0+

// Internal imports
import Common.Utils.Logger
import Common.Constants.AppConstants

/// Defines different types of analytics events
/// Implements Client Analytics requirement from Section 2.2.1
enum AnalyticsEventType {
    case screenView
    case userAction
    case transaction
    case error
    case performance
    case security
}

/// Defines user properties for analytics tracking
/// Implements Client Analytics requirement from Section 2.2.1
enum AnalyticsUserProperty {
    case userId
    case accountType
    case deviceType
    case osVersion
    case appVersion
    case lastLoginDate
}

/// Main service class for handling analytics tracking and reporting
/// Implements System Monitoring requirement from Section 2.5.1
final class AnalyticsService {
    // MARK: - Properties
    
    private let logger: Logger
    private var isEnabled: Bool
    private var userProperties: [String: Any]
    private let analyticsQueue: DispatchQueue
    
    // MARK: - Singleton
    
    static let shared = AnalyticsService()
    
    // MARK: - Constants
    
    private enum Constants {
        static let queueLabel = "com.mintreplicaLite.analytics"
        static let maxBatchSize = 100
        static let maxRetryAttempts = 3
        static let batchTimeInterval: TimeInterval = 60.0 // 1 minute
    }
    
    // MARK: - Initialization
    
    private init() {
        self.logger = Logger.shared
        self.analyticsQueue = DispatchQueue(label: Constants.queueLabel, qos: .utility)
        self.isEnabled = true
        
        // Initialize default user properties
        self.userProperties = [
            "appVersion": AppVersion,
            "bundleId": AppBundleIdentifier,
            "deviceType": UIDevice.current.model,
            "osVersion": UIDevice.current.systemVersion
        ]
    }
    
    // MARK: - Public Methods
    
    /// Tracks an analytics event with associated data
    /// Implements System Monitoring requirement from Section 2.5.1
    func trackEvent(
        eventType: AnalyticsEventType,
        name: String,
        parameters: [String: Any]? = nil
    ) {
        guard isEnabled else { return }
        
        analyticsQueue.async { [weak self] in
            guard let self = self else { return }
            
            var eventData: [String: Any] = [
                "eventType": String(describing: eventType),
                "eventName": name,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "sessionId": self.getCurrentSessionId()
            ]
            
            // Add user properties
            eventData["userProperties"] = self.userProperties
            
            // Add custom parameters
            if let parameters = parameters {
                eventData["parameters"] = parameters
            }
            
            // Log event for monitoring
            self.logger.log(
                "Analytics event tracked: \(name)",
                level: .info,
                category: .userAction
            )
            
            // Queue event for processing
            self.processEvent(eventData)
        }
    }
    
    /// Sets or updates a user property for analytics
    /// Implements Security Logging requirement from Section 6.3.3
    func setUserProperty(property: AnalyticsUserProperty, value: Any) {
        analyticsQueue.async { [weak self] in
            guard let self = self else { return }
            
            let propertyKey = String(describing: property)
            self.userProperties[propertyKey] = value
            
            self.logger.log(
                "Analytics user property updated: \(propertyKey)",
                level: .info,
                category: .userAction
            )
        }
    }
    
    /// Tracks when a screen is viewed
    /// Implements Client Analytics requirement from Section 2.2.1
    func trackScreenView(
        screenName: String,
        additionalParams: [String: Any]? = nil
    ) {
        var parameters = additionalParams ?? [:]
        parameters["screenName"] = screenName
        parameters["viewTimestamp"] = ISO8601DateFormatter().string(from: Date())
        
        trackEvent(
            eventType: .screenView,
            name: "screen_view",
            parameters: parameters
        )
    }
    
    /// Tracks application errors for analytics
    /// Implements Security Logging requirement from Section 6.3.3
    func trackError(
        error: Error,
        context: String? = nil
    ) {
        var parameters: [String: Any] = [
            "errorDescription": error.localizedDescription,
            "errorDomain": (error as NSError).domain,
            "errorCode": (error as NSError).code
        ]
        
        if let context = context {
            parameters["context"] = context
        }
        
        trackEvent(
            eventType: .error,
            name: "error_occurred",
            parameters: parameters
        )
        
        // Log error with appropriate severity
        logger.log(
            "Error tracked: \(error.localizedDescription)",
            level: .error,
            category: .general
        )
    }
    
    // MARK: - Private Methods
    
    private func getCurrentSessionId() -> String {
        // Implement session management logic
        return UUID().uuidString
    }
    
    private func processEvent(_ eventData: [String: Any]) {
        // Add system monitoring data
        var enrichedData = eventData
        enrichedData["memoryUsage"] = getMemoryUsage()
        enrichedData["batteryLevel"] = getBatteryLevel()
        
        // Implement batching and retry logic here
        // This would typically send to CloudWatch or Prometheus
        // For now, just log the event
        logger.log(
            "Processing analytics event: \(enrichedData)",
            level: .debug,
            category: .performance
        )
    }
    
    private func getMemoryUsage() -> Float {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        return kerr == KERN_SUCCESS ? Float(info.resident_size) / 1024.0 / 1024.0 : 0
    }
    
    private func getBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false
        return level
    }
}