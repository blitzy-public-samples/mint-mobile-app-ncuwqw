//
// BiometricAuthView.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify that appropriate biometric usage descriptions are added to Info.plist
// 2. Test biometric authentication on physical devices with Face ID/Touch ID
// 3. Review accessibility labels and hints with UX team
// 4. Validate localized strings for all supported languages

import UIKit // version: iOS 14.0+
import Combine // version: iOS 14.0+

// Relative imports
import "../../../Common/Utils/BiometricAuthManager"
import "../../../Services/AuthenticationService"
import "../../../Common/Extensions/UIView+Extensions"

/// A custom UIView that provides a PSD2-compliant biometric authentication interface
/// Requirement: Biometric Authentication - Implement biometric authentication for secure user access
@IBDesignable
final class BiometricAuthView: UIView {
    
    // MARK: - UI Components
    
    private lazy var biometricIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var authButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.addTarget(self, action: #selector(authButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    
    /// Publisher for authentication state updates
    /// Requirement: Multi-platform user authentication - Handle user authentication across platforms
    let authStatePublisher = PassthroughSubject<AuthenticationState, Never>()
    
    /// Completion handler for authentication result
    var completionHandler: ((Result<Bool, AuthenticationError>) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupSubscriptions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupSubscriptions()
    }
    
    // MARK: - UI Setup
    
    /// Sets up the view's UI components and layout
    /// Requirement: Platform-Specific Security - iOS-specific security measures
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Add subviews
        addSubviews([biometricIconView, titleLabel, messageLabel, authButton, loadingIndicator])
        
        // Apply styling
        roundCorners(radius: 12)
        addShadow(radius: 8, opacity: 0.1, offset: 4, color: .black)
        addBorder(width: 1, color: .separator)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            biometricIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            biometricIconView.topAnchor.constraint(equalTo: topAnchor, constant: 32),
            biometricIconView.widthAnchor.constraint(equalToConstant: 64),
            biometricIconView.heightAnchor.constraint(equalToConstant: 64),
            
            titleLabel.topAnchor.constraint(equalTo: biometricIconView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            
            authButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            authButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            authButton.widthAnchor.constraint(equalToConstant: 200),
            authButton.heightAnchor.constraint(equalToConstant: 44),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: authButton.bottomAnchor, constant: 16),
            loadingIndicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32)
        ])
        
        // Update UI for available biometric type
        updateUIForBiometricType()
    }
    
    /// Sets up Combine subscriptions for authentication state
    private func setupSubscriptions() {
        AuthenticationService.shared.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleAuthenticationState(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Updates
    
    /// Updates the UI based on available biometric authentication type
    /// Requirement: Platform-Specific Security - iOS-specific security measures
    private func updateUIForBiometricType() {
        let biometricType = BiometricAuthManager.shared.availableBiometricType
        
        switch biometricType {
        case .faceID:
            biometricIconView.image = UIImage(systemName: "faceid")
            titleLabel.text = NSLocalizedString("Unlock with Face ID", comment: "Face ID auth title")
            authButton.setTitle(NSLocalizedString("Use Face ID", comment: "Face ID button title"), for: .normal)
            
        case .touchID:
            biometricIconView.image = UIImage(systemName: "touchid")
            titleLabel.text = NSLocalizedString("Unlock with Touch ID", comment: "Touch ID auth title")
            authButton.setTitle(NSLocalizedString("Use Touch ID", comment: "Touch ID button title"), for: .normal)
            
        case .none:
            biometricIconView.image = UIImage(systemName: "exclamationmark.shield")
            titleLabel.text = NSLocalizedString("Biometric Authentication Unavailable", comment: "No biometrics title")
            authButton.setTitle(NSLocalizedString("Try Again", comment: "Retry button title"), for: .normal)
            authButton.isEnabled = false
        }
        
        messageLabel.text = NSLocalizedString("Securely access your account using biometric authentication", comment: "Auth message")
    }
    
    /// Handles authentication state changes
    private func handleAuthenticationState(_ state: AuthenticationState) {
        switch state {
        case .biometricInProgress:
            loadingIndicator.startAnimating()
            authButton.isEnabled = false
            messageLabel.text = NSLocalizedString("Authenticating...", comment: "Auth in progress message")
            
        case .authenticated:
            loadingIndicator.stopAnimating()
            authButton.isEnabled = true
            messageLabel.text = NSLocalizedString("Authentication successful", comment: "Auth success message")
            fadeOut(duration: 0.3) { [weak self] in
                self?.completionHandler?(.success(true))
            }
            
        case .unauthenticated:
            loadingIndicator.stopAnimating()
            authButton.isEnabled = true
            messageLabel.text = NSLocalizedString("Authentication failed. Please try again.", comment: "Auth failed message")
            messageLabel.textColor = .systemRed
            
        case .refreshing:
            loadingIndicator.startAnimating()
            authButton.isEnabled = false
            messageLabel.text = NSLocalizedString("Refreshing authentication...", comment: "Auth refresh message")
        }
    }
    
    // MARK: - Actions
    
    @objc private func authButtonTapped() {
        authenticateWithBiometrics { [weak self] result in
            switch result {
            case .success:
                self?.completionHandler?(.success(true))
            case .failure(let error):
                self?.completionHandler?(.failure(error))
            }
        }
    }
    
    // MARK: - Authentication
    
    /// Initiates PSD2-compliant biometric authentication process
    /// Requirement: Biometric Authentication - Implement biometric authentication for secure user access
    func authenticateWithBiometrics(completion: @escaping (Result<Bool, AuthenticationError>) -> Void) {
        guard BiometricAuthManager.shared.checkBiometricAvailability() else {
            messageLabel.text = NSLocalizedString("Biometric authentication is not available", comment: "No biometrics message")
            messageLabel.textColor = .systemRed
            completion(.failure(.biometricFailed))
            return
        }
        
        authStatePublisher.send(.biometricInProgress)
        
        AuthenticationService.shared.loginWithBiometrics()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.handleAuthenticationResult(.failure(error))
                        completion(.failure(error))
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] success in
                    self?.handleAuthenticationResult(.success(success))
                    completion(.success(success))
                }
            )
            .store(in: &cancellables)
    }
    
    /// Handles the authentication result and updates UI accordingly
    private func handleAuthenticationResult(_ result: Result<Bool, AuthenticationError>) {
        loadingIndicator.stopAnimating()
        authButton.isEnabled = true
        
        switch result {
        case .success(true):
            messageLabel.textColor = .secondaryLabel
            authStatePublisher.send(.authenticated)
            
        case .success(false), .failure:
            messageLabel.textColor = .systemRed
            messageLabel.text = NSLocalizedString("Authentication failed. Please try again.", comment: "Auth failed message")
            authStatePublisher.send(.unauthenticated)
        }
    }
}