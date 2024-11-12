//
// LoginViewController.swift
// MintReplicaLite
//
// Human Tasks:
// 1. Verify OAuth 2.0 client configuration in project settings
// 2. Test biometric authentication on physical devices
// 3. Ensure keychain access is properly configured
// 4. Review accessibility labels with UX team
// 5. Test VoiceOver support for all UI elements

// Third-party Dependencies:
// - UIKit (iOS 14.0+)
// - Combine (iOS 14.0+)

import UIKit
import Combine

// Relative imports
import "../ViewModels/LoginViewModel"
import "../Views/BiometricAuthView"

/// View controller implementing PSD2-compliant login screen functionality
/// Requirements addressed:
/// - Multi-platform user authentication (1.2 Scope/Account Management)
/// - Platform-specific secure storage (2.1 High-Level Architecture Overview/Security Infrastructure)
/// - Biometric Authentication (2.4 Security Architecture/Client Security)
@MainActor final class LoginViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("Email", comment: "Email field placeholder")
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .next
        textField.borderStyle = .roundedRect
        textField.accessibilityIdentifier = "loginEmailTextField"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("Password", comment: "Password field placeholder")
        textField.isSecureTextEntry = true
        textField.returnKeyType = .done
        textField.borderStyle = .roundedRect
        textField.accessibilityIdentifier = "loginPasswordTextField"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Sign In", comment: "Login button title"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.accessibilityIdentifier = "loginButton"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var biometricLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(.systemBlue, for: .normal)
        button.accessibilityIdentifier = "biometricLoginButton"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.accessibilityIdentifier = "loginLoadingIndicator"
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        label.accessibilityIdentifier = "loginErrorLabel"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    
    private let biometricAuthView: BiometricAuthView
    private let viewModel: LoginViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the login view controller with OAuth 2.0 view model
    /// - Parameter viewModel: The view model handling authentication logic
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        self.biometricAuthView = BiometricAuthView()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        // Requirement: Platform-specific secure storage
        setupKeyboardHandling()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(biometricLoginButton)
        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)
        view.addSubview(biometricAuthView)
        
        // Configure biometric auth view
        biometricAuthView.isHidden = true
        biometricAuthView.layer.cornerRadius = 12
        
        NSLayoutConstraint.activate([
            // Email text field
            emailTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Password text field
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Login button
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Biometric login button
            biometricLoginButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            biometricLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: biometricLoginButton.bottomAnchor, constant: 16),
            
            // Error label
            errorLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            
            // Biometric auth view
            biometricAuthView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            biometricAuthView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            biometricAuthView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            biometricAuthView.heightAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        // Requirement: Multi-platform user authentication
        let loginTrigger = loginButton.publisher(for: .touchUpInside)
            .map { [weak self] _ -> (email: String, password: String) in
                return (
                    email: self?.emailTextField.text ?? "",
                    password: self?.passwordTextField.text ?? ""
                )
            }
            .eraseToAnyPublisher()
        
        // Requirement: Biometric Authentication
        let biometricTrigger = biometricLoginButton.publisher(for: .touchUpInside)
            .map { _ in }
            .eraseToAnyPublisher()
        
        let input = LoginViewModel.Input(
            loginTrigger: loginTrigger,
            biometricTrigger: biometricTrigger,
            viewAppeared: Just(()).eraseToAnyPublisher()
        )
        
        let output = viewModel.transform(input)
        
        // Bind loading state
        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.loginButton.isEnabled = false
                    self?.biometricLoginButton.isEnabled = false
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.loginButton.isEnabled = true
                    self?.biometricLoginButton.isEnabled = true
                }
            }
            .store(in: &cancellables)
        
        // Bind error messages
        output.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorLabel.text = error.localizedDescription
                self?.errorLabel.isHidden = false
                UIAccessibility.post(notification: .announcement, argument: error.localizedDescription)
            }
            .store(in: &cancellables)
        
        // Bind biometric availability
        output.isBiometricAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAvailable in
                self?.biometricLoginButton.isHidden = !isAvailable
                if isAvailable {
                    let biometricType = self?.biometricAuthView.authStatePublisher.value == .faceID ? "Face ID" : "Touch ID"
                    self?.biometricLoginButton.setTitle("Sign in with \(biometricType)", for: .normal)
                }
            }
            .store(in: &cancellables)
        
        // Bind login success
        output.loginSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleLoginResult(.success(true))
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleKeyboardNotification(notification)
            }
            .store(in: &cancellables)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func handleKeyboardNotification(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let keyboardHeight = notification.name == UIResponder.keyboardWillShowNotification ? keyboardFrame.height : 0
        UIView.animate(withDuration: 0.3) {
            self.view.frame.origin.y = -keyboardHeight/2
        }
    }
    
    // MARK: - Authentication Result Handling
    
    private func handleLoginResult(_ result: Result<Bool, Error>) {
        switch result {
        case .success:
            // Clear sensitive data
            emailTextField.text = nil
            passwordTextField.text = nil
            errorLabel.isHidden = true
            
            // Notify accessibility
            UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Login successful", comment: "Login success message"))
            
            // Dismiss view controller
            dismiss(animated: true)
            
        case .failure(let error):
            errorLabel.text = error.localizedDescription
            errorLabel.isHidden = false
            
            // Notify accessibility
            UIAccessibility.post(notification: .announcement, argument: error.localizedDescription)
        }
    }
}