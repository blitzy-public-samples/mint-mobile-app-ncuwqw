//
// ErrorView.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify accessibility labels and traits are properly configured for VoiceOver support
// 2. Test error view layout on different device sizes and orientations
// 3. Validate error icon assets are available in asset catalog

// UIKit framework - iOS 14.0+
import UIKit

// Internal imports for styling and extensions
import Common.Extensions.UIView_Extensions
import Common.Constants.AppConstants

/// A reusable error view component for displaying error states with consistent styling
/// Implements 'iOS Native UI Implementation' requirement from Section 1.1 System Overview
/// Implements 'UI Component Styling' requirement from Section 5.1.2 Screen Layouts
final class ErrorView: UIView {
    
    // MARK: - Private Properties
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = AppConstants.UI.defaultPadding
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Public Properties
    
    var retryAction: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureLayout()
        applyDefaultStyling()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        configureLayout()
        applyDefaultStyling()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        contentStackView.addArrangedSubview(iconImageView)
        contentStackView.addArrangedSubview(messageLabel)
        contentStackView.addArrangedSubview(retryButton)
        
        addSubviews([contentStackView])
        
        retryButton.addTarget(self, action: #selector(handleRetryTapped), for: .touchUpInside)
    }
    
    private func configureLayout() {
        NSLayoutConstraint.activate([
            contentStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppConstants.UI.defaultPadding),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppConstants.UI.defaultPadding),
            
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            iconImageView.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func applyDefaultStyling() {
        roundCorners(radius: AppConstants.UI.defaultCornerRadius)
    }
    
    @objc private func handleRetryTapped() {
        retryAction?()
    }
    
    // MARK: - Public Methods
    
    /// Configures the error view with custom message and optional retry action
    /// - Parameters:
    ///   - message: The error message to display
    ///   - icon: Optional icon to display above the message
    ///   - retryButtonTitle: Optional title for the retry button
    ///   - retryAction: Optional closure to execute when retry button is tapped
    func configure(
        message: String,
        icon: UIImage? = nil,
        retryButtonTitle: String? = nil,
        retryAction: (() -> Void)? = nil
    ) {
        messageLabel.text = message
        iconImageView.image = icon
        iconImageView.isHidden = icon == nil
        
        if let retryButtonTitle = retryButtonTitle {
            retryButton.setTitle(retryButtonTitle, for: .normal)
            retryButton.isHidden = false
            self.retryAction = retryAction
        } else {
            retryButton.isHidden = true
            self.retryAction = nil
        }
        
        // Update stack view spacing based on visible components
        contentStackView.spacing = icon == nil ? AppConstants.UI.defaultPadding / 2 : AppConstants.UI.defaultPadding
    }
}