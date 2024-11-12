//
// AppCoordinator.swift
// MintReplicaLite
//
// Human Tasks:
// 1. Verify UIKit and Combine frameworks are properly linked in Xcode project settings
// 2. Ensure minimum iOS deployment target is set to iOS 14.0 or higher
// 3. Configure proper view controller initialization in concrete coordinator implementations
// 4. Review and test navigation transitions for smooth user experience

// Third-party Dependencies:
// - UIKit (iOS 14.0+)
// - Combine (iOS 14.0+)

import UIKit
import Combine

// Relative imports
import "../Common/Protocols/Coordinator"
import "../Services/AuthenticationService"
import "../Presentation/Authentication/ViewControllers/LoginViewController"

/// Main application coordinator managing navigation flow and screen transitions with PSD2-compliant authentication
/// Requirements addressed:
/// - Client Applications Architecture (2.2.1): Implements navigation coordination pattern for iOS native application
/// - Authentication Flow (6.1.1): Manages navigation flow between authenticated and non-authenticated states
/// - Multi-platform user authentication (1.2 Scope/Account Management): Coordinates OAuth 2.0 authentication flow
@MainActor final class AppCoordinator: Coordinator {
    
    // MARK: - Properties
    
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator]
    private let window: UIWindow
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the app coordinator with a window instance
    /// - Parameter window: The main window for the application
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.childCoordinators = []
        
        // Configure navigation controller appearance
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .systemBlue
        
        // Set up authentication state observation
        setupAuthenticationObserver()
    }
    
    // MARK: - Coordinator Protocol Implementation
    
    /// Starts the coordinator and sets up initial navigation flow
    /// Requirement: Client Applications Architecture - Implements navigation coordination pattern
    func start() {
        // Set up root view controller
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        // Check initial authentication state and route accordingly
        if AuthenticationService.shared.isAuthenticated {
            showMainFlow()
        } else {
            showAuthenticationFlow()
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up authentication state observation using Combine
    /// Requirement: Authentication Flow - Manages navigation flow between states
    private func setupAuthenticationObserver() {
        AuthenticationService.shared.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .authenticated:
                    self?.showMainFlow()
                case .unauthenticated:
                    self?.showAuthenticationFlow()
                case .refreshing, .biometricInProgress:
                    // Handle intermediate states if needed
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    /// Presents the PSD2-compliant authentication flow
    /// Requirement: Multi-platform user authentication - OAuth 2.0 flow
    private func showAuthenticationFlow() {
        // Create and configure login view controller
        let loginViewModel = LoginViewModel(authService: AuthenticationService.shared)
        let loginViewController = LoginViewController(viewModel: loginViewModel)
        
        // Configure navigation appearance for auth flow
        navigationController.setNavigationBarHidden(true, animated: false)
        
        // Perform transition with fade animation
        UIView.transition(with: window,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: { [weak self] in
            self?.navigationController.setViewControllers([loginViewController], animated: false)
        })
        
        // Clean up any existing child coordinators
        childCoordinators.removeAll()
    }
    
    /// Presents the main application flow for authenticated users
    /// Requirement: Client Applications Architecture - Navigation management
    private func showMainFlow() {
        // Create main flow coordinator
        let mainCoordinator = MainTabCoordinator(navigationController: navigationController)
        
        // Add to child coordinators and start
        childCoordinators.append(mainCoordinator)
        mainCoordinator.start()
        
        // Configure navigation appearance for main flow
        navigationController.setNavigationBarHidden(false, animated: false)
        
        // Perform transition with fade animation
        UIView.transition(with: window,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: nil)
    }
    
    /// Handles changes in OAuth 2.0 authentication state
    /// Requirement: Authentication Flow - PSD2-compliant state management
    private func handleAuthenticationStateChange(isAuthenticated: Bool) {
        if isAuthenticated {
            showMainFlow()
        } else {
            showAuthenticationFlow()
        }
    }
}