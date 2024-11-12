//
// LoadingView.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify activity indicator color matches app theme
// 2. Test loading view appearance on different screen sizes
// 3. Validate message label font matches design system specifications

// UIKit framework - iOS 14.0+
import UIKit

// Internal imports for styling and animations
import Common.Extensions.UIView_Extensions
import Common.Constants.AppConstants

/// A reusable loading view component that displays an activity indicator with optional text message
/// Implements 'iOS Native UI Implementation' requirement from Section 1.1 System Overview
/// Implements 'UI Component Styling' requirement from Section 5.1.2 Screen Layouts
public class LoadingView: UIView {
    
    // MARK: - Private Properties
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = AppConstants.UI.defaultCornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .systemBlue
        return indicator
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Public Properties
    
    public var message: String? {
        didSet {
            messageLabel.text = message
            messageLabel.isHidden = message == nil
            setupConstraints()
        }
    }
    
    // MARK: - Initialization
    
    public init(message: String? = nil, frame: CGRect = .zero) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubviews([containerView])
        containerView.addSubviews([activityIndicator, messageLabel])
        
        self.message = message
        messageLabel.text = message
        messageLabel.isHidden = message == nil
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        return nil
    }
    
    // MARK: - Private Methods
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view constraints
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            // Activity indicator constraints
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: AppConstants.UI.defaultPadding),
            
            // Message label constraints
            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: AppConstants.UI.defaultPadding),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppConstants.UI.defaultPadding),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppConstants.UI.defaultPadding),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -AppConstants.UI.defaultPadding)
        ])
    }
    
    // MARK: - Public Methods
    
    /// Shows the loading view with an optional message
    /// - Parameter message: Optional text message to display below the activity indicator
    public func show(message: String? = nil) {
        if let message = message {
            self.message = message
        }
        
        activityIndicator.startAnimating()
        fadeIn(duration: TimeInterval(AppConstants.UI.defaultAnimationDuration))
    }
    
    /// Hides the loading view with animation
    public func hide() {
        fadeOut(duration: TimeInterval(AppConstants.UI.defaultAnimationDuration)) { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.removeFromSuperview()
        }
    }
}