//
// StoryboardInstantiable.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Ensure all storyboard files follow the naming convention where the storyboard identifier matches the view controller class name
// 2. Set up storyboard identifiers in Interface Builder for all view controllers that will use this protocol
// 3. Verify iOS deployment target is set to iOS 14.0 or higher in project settings

import UIKit // @version iOS 14.0+

/// Protocol that provides a standardized way to instantiate view controllers from storyboards.
/// Implements view controller instantiation pattern for iOS native application built with Swift and UIKit.
/// Requirement addressed: Client Applications Architecture (2.2.1)
protocol StoryboardInstantiable {
    /// The storyboard identifier for the view controller. By default, this should match the class name.
    static var storyboardIdentifier: String { get }
    
    /// The name of the storyboard file containing the view controller.
    static var storyboardName: String { get }
}

extension StoryboardInstantiable {
    /// Default implementation assumes the storyboard identifier matches the class name
    static var storyboardIdentifier: String {
        // Using String describing to get the class name at runtime
        String(describing: self)
    }
}

extension StoryboardInstantiable where Self: UIViewController {
    /// Instantiates a view controller from a storyboard using the specified identifier.
    /// Requirement addressed: iOS UI Architecture (5.1.7)
    /// - Returns: An instance of the view controller type that conforms to this protocol.
    /// - Throws: A fatal error if the view controller cannot be instantiated from the storyboard.
    static func instantiate() -> Self {
        // Get the storyboard instance using the specified name
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        
        // Attempt to instantiate the view controller with the specified identifier
        guard let viewController = storyboard.instantiateViewController(withIdentifier: storyboardIdentifier) as? Self else {
            fatalError("""
                Failed to instantiate view controller with identifier '\(storyboardIdentifier)' \
                from storyboard '\(storyboardName)'.
                Please ensure:
                1. The storyboard exists in the main bundle
                2. The storyboard identifier is correctly set in Interface Builder
                3. The view controller class is correctly set in Interface Builder
                """)
        }
        
        return viewController
    }
}