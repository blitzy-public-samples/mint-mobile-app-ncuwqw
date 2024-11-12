//
// AccountCell.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify accessibility labels and traits are properly configured for VoiceOver support
// 2. Test cell layout on different device sizes to ensure proper scaling
// 3. Validate color contrast ratios meet WCAG guidelines

// UIKit framework - iOS 14.0+
import UIKit

// Relative imports for dependencies
import "../../../Domain/Models/Account"
import "../../../Common/Extensions/UIView+Extensions"
import "../../../Common/Constants/AppConstants"

/// Custom UITableViewCell for displaying account information
/// Implements:
/// - Account Management (Section 1.2): Display of financial account information
/// - UI Component Design (Section 5.1.2): Consistent account list view styling
@IBDesignable
class AccountCell: UITableViewCell {
    
    // MARK: - UI Properties
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var balanceLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var statusIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Data Properties
    private var account: Account?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Configure cell appearance
        backgroundColor = .systemBackground
        selectionStyle = .none
        
        // Add shadow and corner radius
        contentView.addShadow(
            radius: 4,
            opacity: 0.1,
            offset: 2,
            color: .black
        )
        contentView.roundCorners(radius: AppConstants.UI.defaultCornerRadius)
        
        // Add subviews
        contentView.addSubviews([nameLabel, typeLabel, balanceLabel, statusIndicator])
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Status indicator constraints
            statusIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppConstants.UI.defaultPadding),
            statusIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            // Name label constraints
            nameLabel.leadingAnchor.constraint(equalTo: statusIndicator.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppConstants.UI.defaultPadding),
            nameLabel.trailingAnchor.constraint(equalTo: balanceLabel.leadingAnchor, constant: -AppConstants.UI.defaultPadding),
            
            // Type label constraints
            typeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            typeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            typeLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            typeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppConstants.UI.defaultPadding),
            
            // Balance label constraints
            balanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppConstants.UI.defaultPadding),
            balanceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            balanceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }
    
    // MARK: - Configuration
    /// Configures the cell with account data
    /// - Parameter account: The account model to display
    func configure(with account: Account) {
        self.account = account
        
        nameLabel.text = account.name
        typeLabel.text = account.type.rawValue.capitalized
        balanceLabel.text = account.formattedBalance()
        
        // Configure status indicator
        statusIndicator.image = account.isActive ?
            UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal) :
            UIImage(systemName: "exclamationmark.circle.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        
        // Apply type-specific styling
        switch account.type {
        case .checking, .savings:
            typeLabel.textColor = .systemBlue
        case .credit:
            typeLabel.textColor = .systemPurple
        case .investment:
            typeLabel.textColor = .systemGreen
        case .loan:
            typeLabel.textColor = .systemRed
        case .other:
            typeLabel.textColor = .secondaryLabel
        }
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        
        account = nil
        nameLabel.text = nil
        typeLabel.text = nil
        balanceLabel.text = nil
        statusIndicator.image = nil
        typeLabel.textColor = .secondaryLabel
    }
}