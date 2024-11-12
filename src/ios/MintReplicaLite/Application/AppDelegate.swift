//
// AppDelegate.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Configure push notification capabilities in Xcode project settings
// 2. Set up proper provisioning profiles with push notification entitlements
// 3. Verify APNS certificates are properly configured in Apple Developer Portal
// 4. Configure launch screen and initial view controller in Main.storyboard
// 5. Review analytics event tracking configuration for app lifecycle events

// UIKit framework - iOS 14.0+
import UIKit
// UserNotifications framework - iOS 14.0+
import UserNotifications

// Internal imports
import "Application/AppConfiguration"
import "Services/PushNotificationService"
import "Services/AnalyticsService"

/// Main application delegate class handling app lifecycle and system events
/// Implements iOS Application Entry Point requirement from Section 1.1
@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - Properties
    
    var window: UIWindow?
    private let pushService = PushNotificationService.shared
    private let analyticsService = AnalyticsService.shared
    
    // MARK: - UIApplication Lifecycle
    
    /// Application launch point handling initial setup and configuration
    /// Implements Application Configuration requirement from Section 2.2.1
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure application environment
        AppConfiguration.shared.configure(environment: .production)
        
        // Setup window and initial view controller
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else {
            return false
        }
        
        // Configure root view controller
        if let rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController() {
            window.rootViewController = rootViewController
        }
        window.makeKeyAndVisible()
        
        // Initialize push notification service
        UNUserNotificationCenter.current().delegate = self
        
        // Request push notification authorization
        pushService.requestAuthorization { [weak self] granted, error in
            guard let self = self else { return }
            
            if granted {
                // Register for remote notifications if authorized
                self.pushService.registerForPushNotifications()
                
                // Track successful push notification authorization
                self.analyticsService.trackEvent(
                    eventType: .userAction,
                    name: "push_notification_authorized"
                )
            } else if let error = error {
                // Track authorization error
                self.analyticsService.trackError(
                    error: error,
                    context: "push_notification_authorization"
                )
            }
        }
        
        // Track app launch event
        analyticsService.trackEvent(
            eventType: .userAction,
            name: "app_launched",
            parameters: [
                "launch_type": launchOptions != nil ? "background" : "normal",
                "api_base_url": AppConfiguration.shared.getAPIBaseURL()
            ]
        )
        
        return true
    }
    
    // MARK: - Push Notification Registration
    
    /// Handles successful push notification registration
    /// Implements Push Notification Integration requirement from Section 2.1
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert token data to string format
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        // Update push notification service with token
        pushService.updateDeviceToken(token)
        
        // Track successful registration
        analyticsService.trackEvent(
            eventType: .userAction,
            name: "push_notification_registered",
            parameters: ["device_token": token]
        )
    }
    
    /// Handles failed push notification registration
    /// Implements Push Notification Integration requirement from Section 2.1
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Track registration failure
        analyticsService.trackError(
            error: error,
            context: "push_notification_registration"
        )
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Handles notification presentation while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle notification presentation
        pushService.handleNotification(notification)
        
        // Configure presentation options
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handles notification response when user interacts with notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification response
        pushService.handleNotification(response.notification)
        
        // Track notification interaction
        analyticsService.trackEvent(
            eventType: .userAction,
            name: "push_notification_opened",
            parameters: [
                "notification_id": response.notification.request.identifier,
                "action_id": response.actionIdentifier
            ]
        )
        
        completionHandler()
    }
}