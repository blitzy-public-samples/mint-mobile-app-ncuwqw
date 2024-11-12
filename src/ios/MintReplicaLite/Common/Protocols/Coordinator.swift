//
// Coordinator.swift
// MintReplicaLite
//
// Human Tasks:
// 1. Ensure UIKit is properly linked in the Xcode project settings
// 2. Verify minimum iOS deployment target is set to iOS 14.0 or higher
// 3. Configure proper view controller initialization in concrete coordinator implementations

// UIKit version: iOS 14.0+
import UIKit

/// Coordinator protocol that defines the core requirements for navigation coordination in the application
/// Addresses requirements:
/// - Client Applications Architecture (2.2.1): Implements navigation coordination pattern for iOS native application
/// - Authentication Flow (6.1.1): Supports secure navigation flow management between states
protocol Coordinator: AnyObject {
    /// The navigation controller used by this coordinator to manage view hierarchy
    var navigationController: UINavigationController { get set }
    
    /// Array of child coordinators managed by this coordinator
    var childCoordinators: [Coordinator] { get set }
    
    /// Starts the coordinator's flow and sets up initial navigation state
    func start()
}

// MARK: - Default Implementations
extension Coordinator {
    /// Default implementation providing an empty array for child coordinators
    /// This reduces boilerplate code in concrete implementations while maintaining flexibility
    var childCoordinators: [Coordinator] {
        get { [] }
        set { }
    }
}