//
// EmptyStateView.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify accessibility labels and traits are properly configured for VoiceOver support
// 2. Test empty state view with different content lengths to ensure proper layout adaptation
// 3. Validate color contrast ratios meet WCAG guidelines for text readability

// UIKit framework - iOS 14.0+
import UIKit

// Internal imports for view extensions and constants
import Common.Extensions.UIView_Extensions
import Common.Constants.AppConstants

/// A reusable view component that displays an empty state with customizable content
/// Implements 'iOS Native UI Implementation' requirement from Section 1.1 System Overview
/// Implements 'UI Component Styling' requirement from Section 5.1.2 Screen Layouts
final class EmptyStateView: UIView {
    
    // MARK: - UI Components
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var contentStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = AppConstants.UI.defaultPadding
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Properties
    
    private var actionHandler: ((UIButton) -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Add content stack to view hierarchy
        addSubviews([contentStack])
        
        // Add components to stack
        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(messageLabel)
        contentStack.addArrangedSubview(actionButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: AppConstants.UI.defaultPadding),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -AppConstants.UI.defaultPadding),
            
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 200),
            imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 200)
        ])
        
        // Hide all components initially
        imageView.isHidden = true
        titleLabel.isHidden = true
        messageLabel.isHidden = true
        actionButton.isHidden = true
    }
    
    // MARK: - Configuration
    
    /// Configures the empty state view with the provided content
    /// - Parameters:
    ///   - image: Optional image to display
    ///   - title: Optional title text
    ///   - message: Optional message text
    ///   - buttonTitle: Optional button title
    ///   - action: Optional button action handler
    func configure(
        image: UIImage? = nil,
        title: String? = nil,
        message: String? = nil,
        buttonTitle: String? = nil,
        action: ((UIButton) -> Void)? = nil
    ) {
        // Configure image
        imageView.image = image
        imageView.isHidden = image == nil
        
        // Configure title
        titleLabel.text = title
        titleLabel.isHidden = title == nil
        
        // Configure message
        messageLabel.text = message
        messageLabel.isHidden = message == nil
        
        // Configure action button
        if let buttonTitle = buttonTitle {
            actionButton.setTitle(buttonTitle, for: .normal)
            actionHandler = action
            actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
            actionButton.isHidden = action == nil
        } else {
            actionButton.isHidden = true
            actionHandler = nil
        }
        
        // Update stack spacing based on visible components
        contentStack.arrangedSubviews.forEach { view in
            let spacing = view.isHidden ? 0 : AppConstants.UI.defaultPadding
            contentStack.setCustomSpacing(spacing, after: view)
        }
        
        // Animate appearance
        fadeIn()
    }
    
    // MARK: - Actions
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        actionHandler?(sender)
    }
}