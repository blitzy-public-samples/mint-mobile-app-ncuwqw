//
// SettingsViewController.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify biometric authentication entitlements are enabled in project settings
// 2. Add NSFaceIDUsageDescription key to Info.plist with appropriate message
// 3. Configure notification permissions in project capabilities
// 4. Review UI layout with design team for accessibility compliance
//
// Third-party Dependencies:
// - UIKit (iOS 14.0+)
// - Combine (iOS 14.0+)

import UIKit
import Combine

// Relative imports
import Presentation.Settings.ViewModels.SettingsViewModel

/// View controller responsible for managing and displaying app settings
/// Requirements addressed:
/// - Security Infrastructure (1.1): Implements platform-specific secure storage (Keychain) and biometric authentication settings
/// - Client Security (2.4): Manages biometric authentication and secure storage configuration through user interface
/// - Platform-Specific Security (6.3.4): Provides interface for managing iOS-specific security features
final class SettingsViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let viewModel: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private let settingsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let biometricLabel: UILabel = {
        let label = UILabel()
        label.text = "Use Biometric Authentication"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let biometricSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .systemBlue
        return toggle
    }()
    
    private let notificationLabel: UILabel = {
        let label = UILabel()
        label.text = "Enable Notifications"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let notificationSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .systemBlue
        return toggle
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    // MARK: - Initialization
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    // MARK: - Private Methods
    
    /// Sets up the view controller's UI components and layout
    /// Requirements addressed:
    /// - Platform-Specific Security (6.3.4): iOS-specific UI layout for security settings
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Settings"
        
        // Configure navigation bar
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Create container views for switches
        let biometricContainer = createSwitchContainer(
            label: biometricLabel,
            toggle: biometricSwitch
        )
        let notificationContainer = createSwitchContainer(
            label: notificationLabel,
            toggle: notificationSwitch
        )
        
        // Add components to stack view
        settingsStackView.addArrangedSubview(biometricContainer)
        settingsStackView.addArrangedSubview(notificationContainer)
        settingsStackView.addArrangedSubview(createSeparator())
        settingsStackView.addArrangedSubview(logoutButton)
        
        // Add stack view to main view
        view.addSubview(settingsStackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            settingsStackView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 20
            ),
            settingsStackView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 20
            ),
            settingsStackView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -20
            )
        ])
        
        // Apply styling
        biometricContainer.addShadow(
            radius: 4,
            opacity: 0.1,
            offset: 2,
            color: .black
        )
        biometricContainer.roundCorners(radius: 8)
        biometricContainer.addBorder(width: 1, color: .systemGray5)
        
        notificationContainer.addShadow(
            radius: 4,
            opacity: 0.1,
            offset: 2,
            color: .black
        )
        notificationContainer.roundCorners(radius: 8)
        notificationContainer.addBorder(width: 1, color: .systemGray5)
    }
    
    /// Creates a container view for a switch setting
    private func createSwitchContainer(label: UILabel, toggle: UISwitch) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        container.addSubview(toggle)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        toggle.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 56),
            
            label.leadingAnchor.constraint(
                equalTo: container.leadingAnchor,
                constant: 16
            ),
            label.centerYAnchor.constraint(
                equalTo: container.centerYAnchor
            ),
            
            toggle.trailingAnchor.constraint(
                equalTo: container.trailingAnchor,
                constant: -16
            ),
            toggle.centerYAnchor.constraint(
                equalTo: container.centerYAnchor
            )
        ])
        
        return container
    }
    
    /// Creates a separator line
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .systemGray5
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
    
    /// Binds view model inputs and outputs
    /// Requirements addressed:
    /// - Security Infrastructure (1.1): Binds secure storage and authentication settings
    /// - Client Security (2.4): Manages security feature state through view model
    private func bindViewModel() {
        // Create input from UI controls
        let input = SettingsViewModel.Input(
            biometricToggle: biometricSwitch.publisher(for: .valueChanged)
                .map { $0.isOn }
                .eraseToAnyPublisher(),
            notificationToggle: notificationSwitch.publisher(for: .valueChanged)
                .map { $0.isOn }
                .eraseToAnyPublisher(),
            logoutTap: logoutButton.publisher(for: .touchUpInside)
                .map { _ in }
                .eraseToAnyPublisher()
        )
        
        // Transform input to output
        let output = viewModel.transform(input)
        
        // Bind outputs to UI
        output.isBiometricEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.biometricSwitch.setOn(enabled, animated: true)
            }
            .store(in: &cancellables)
        
        output.isNotificationsEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.notificationSwitch.setOn(enabled, animated: true)
            }
            .store(in: &cancellables)
        
        output.error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
        
        output.didLogout
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleLogout()
            }
            .store(in: &cancellables)
    }
    
    /// Handles errors from the view model
    private func handleError(_ error: SettingsViewModelError) {
        let title: String
        let message: String
        
        switch error {
        case .biometricNotAvailable:
            title = "Biometric Authentication Unavailable"
            message = "Your device does not support or has not configured biometric authentication."
        case .biometricAuthFailed:
            title = "Authentication Failed"
            message = "Failed to authenticate using biometrics. Please try again."
        case .notificationPermissionDenied:
            title = "Notifications Disabled"
            message = "Please enable notifications in your device settings to receive updates."
        case .logoutFailed:
            title = "Logout Failed"
            message = "Failed to logout. Please try again."
        }
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    /// Handles successful logout
    private func handleLogout() {
        // Navigate to login screen
        // Note: Actual navigation logic should be handled by the coordinator pattern
        // or navigation service in a production app
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        window?.rootViewController = UINavigationController()
        window?.makeKeyAndVisible()
    }
}