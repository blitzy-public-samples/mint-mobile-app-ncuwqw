//
// PushNotificationService.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Configure push notification capabilities in Xcode project settings
// 2. Set up Apple Push Notification Service (APNS) certificates in Apple Developer Portal
// 3. Configure notification categories and actions in Apple Developer Portal
// 4. Verify proper provisioning profile with push notification entitlements
// 5. Test notification delivery in sandbox environment before production

// Foundation framework - iOS 14.0+
import Foundation
// UserNotifications framework - iOS 14.0+
import UserNotifications
// UIKit framework - iOS 14.0+
import UIKit

// Internal imports
import Common.Constants.AppConstants
import Common.Utils.Logger

/// Protocol defining methods for handling push notification events
/// Implements Real-time Updates requirement from Section 3.3.3
protocol PushNotificationDelegate: AnyObject {
    func didReceiveNotification(_ notification: UNNotification)
    func didRegisterForPushNotifications(_ deviceToken: String)
}

/// Core service managing push notification functionality for iOS platform
/// Implements Push Notification Integration requirement from Section 2.1
@available(iOS 14.0, *)
final class PushNotificationService: NSObject {
    
    // MARK: - Properties
    
    /// Singleton instance for centralized notification management
    static let shared = PushNotificationService()
    
    /// Reference to system notification center
    private let notificationCenter: UNUserNotificationCenter
    
    /// Delegate to handle notification events
    weak var delegate: PushNotificationDelegate?
    
    /// Device token for APNS identification
    private(set) var deviceToken: String?
    
    // MARK: - Initialization
    
    private override init() {
        self.notificationCenter = UNUserNotificationCenter.current()
        super.init()
        
        // Configure notification center delegate
        notificationCenter.delegate = self
        
        // Set up notification categories
        configureNotificationCategories()
        
        Logger.shared.log(
            "PushNotificationService initialized",
            level: .info,
            category: .general
        )
    }
    
    // MARK: - Public Methods
    
    /// Requests notification permissions from the user
    /// Implements Alert Delivery requirement from Section 3.1.2
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) { [weak self] granted, error in
            guard let self = self else { return }
            
            if let error = error {
                Logger.shared.log(
                    "Failed to request notification authorization: \(error.localizedDescription)",
                    level: .error,
                    category: .general
                )
            } else {
                Logger.shared.log(
                    "Notification authorization status: \(granted)",
                    level: .info,
                    category: .general
                )
            }
            
            DispatchQueue.main.async {
                completion(granted, error)
            }
        }
    }
    
    /// Registers device for remote notifications
    /// Implements Push Notification Integration requirement from Section 2.1
    func registerForPushNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            
            Logger.shared.log(
                "Registering for remote notifications",
                level: .info,
                category: .general
            )
        }
    }
    
    /// Processes received notifications
    /// Implements Real-time Updates requirement from Section 3.3.3
    func handleNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        Logger.shared.log(
            "Received notification: \(userInfo)",
            level: .info,
            category: .general
        )
        
        // Forward to delegate
        delegate?.didReceiveNotification(notification)
        
        // Process based on notification type
        if let topic = userInfo["topic"] as? String {
            switch topic {
            case AppConstants.Notifications.budgetAlertTopic:
                processBudgetAlert(userInfo)
            case AppConstants.Notifications.goalAlertTopic:
                processGoalAlert(userInfo)
            case AppConstants.Notifications.transactionAlertTopic:
                processTransactionAlert(userInfo)
            default:
                Logger.shared.log(
                    "Unknown notification topic: \(topic)",
                    level: .warning,
                    category: .general
                )
            }
        }
    }
    
    /// Updates the device token and syncs with backend
    /// Implements Push Notification Integration requirement from Section 2.1
    func updateDeviceToken(_ token: String) {
        deviceToken = token
        
        Logger.shared.log(
            "Device token updated: \(token)",
            level: .info,
            category: .general
        )
        
        delegate?.didRegisterForPushNotifications(token)
    }
    
    // MARK: - Private Methods
    
    private func configureNotificationCategories() {
        // Configure notification categories and actions
        let categories: Set<UNNotificationCategory> = [
            createBudgetAlertCategory(),
            createGoalAlertCategory(),
            createTransactionAlertCategory()
        ]
        
        notificationCenter.setNotificationCategories(categories)
    }
    
    private func createBudgetAlertCategory() -> UNNotificationCategory {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_BUDGET",
            title: "View Budget",
            options: .foreground
        )
        
        return UNNotificationCategory(
            identifier: "BUDGET_ALERT",
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
    }
    
    private func createGoalAlertCategory() -> UNNotificationCategory {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_GOAL",
            title: "View Goal",
            options: .foreground
        )
        
        return UNNotificationCategory(
            identifier: "GOAL_ALERT",
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
    }
    
    private func createTransactionAlertCategory() -> UNNotificationCategory {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_TRANSACTION",
            title: "View Transaction",
            options: .foreground
        )
        
        return UNNotificationCategory(
            identifier: "TRANSACTION_ALERT",
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
    }
    
    private func processBudgetAlert(_ userInfo: [AnyHashable: Any]) {
        Logger.shared.log(
            "Processing budget alert notification",
            level: .debug,
            category: .general
        )
    }
    
    private func processGoalAlert(_ userInfo: [AnyHashable: Any]) {
        Logger.shared.log(
            "Processing goal alert notification",
            level: .debug,
            category: .general
        )
    }
    
    private func processTransactionAlert(_ userInfo: [AnyHashable: Any]) {
        Logger.shared.log(
            "Processing transaction alert notification",
            level: .debug,
            category: .general
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    /// Handles notification presentation while app is in foreground
    /// Implements Alert Delivery requirement from Section 3.1.2
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handleNotification(notification)
        
        // Configure presentation options for foreground notifications
        let presentationOptions: UNNotificationPresentationOptions = [.banner, .sound, .badge]
        completionHandler(presentationOptions)
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let notification = response.notification
        handleNotification(notification)
        completionHandler()
    }
}