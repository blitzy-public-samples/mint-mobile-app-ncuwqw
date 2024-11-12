// HUMAN TASKS:
// 1. Verify accessibility labels and traits are properly configured for VoiceOver support
// 2. Review cell reuse performance with large transaction lists
// 3. Validate color schemes match design system for transaction status indicators

// UIKit framework - iOS 14.0+
import UIKit

// Relative imports
import "../../../Domain/Models/Transaction"
import "../../../Common/Extensions/UIView+Extensions"
import "../../../Common/Extensions/Decimal+Extensions"

/// Custom UITableViewCell for displaying transaction information
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking): Display of transaction details in list format
/// - UI Component Design (5.1.2 Screen Layouts): Consistent styling and layout
@IBDesignable
class TransactionCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let typeIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Properties
    
    private var transaction: Transaction?
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
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
        
        // Add subviews
        contentView.addSubview(typeIconImageView)
        contentView.addSubview(contentStackView)
        contentView.addSubview(amountLabel)
        
        // Configure stack view
        contentStackView.addArrangedSubview(descriptionLabel)
        
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 8
        bottomStack.addArrangedSubview(dateLabel)
        bottomStack.addArrangedSubview(categoryLabel)
        contentStackView.addArrangedSubview(bottomStack)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            typeIconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            typeIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            typeIconImageView.widthAnchor.constraint(equalToConstant: 24),
            typeIconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            contentStackView.leadingAnchor.constraint(equalTo: typeIconImageView.trailingAnchor, constant: 12),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            amountLabel.leadingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 12),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            amountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        // Apply styling
        contentView.roundCorners(radius: 8)
        contentView.addShadow(radius: 4, opacity: 0.1, offset: 2, color: .black)
    }
    
    // MARK: - Configuration
    
    /// Configures the cell with transaction data
    /// - Parameter transaction: The transaction to display
    func configure(with transaction: Transaction) {
        self.transaction = transaction
        
        // Configure amount
        amountLabel.text = transaction.formattedAmount()
        amountLabel.textColor = transaction.type == .debit ? .systemRed : .systemGreen
        
        // Configure description and date
        descriptionLabel.text = transaction.description
        dateLabel.text = dateFormatter.string(from: transaction.date)
        
        // Configure type icon
        switch transaction.type {
        case .debit:
            typeIconImageView.image = UIImage(systemName: "arrow.down.circle.fill")
        case .credit:
            typeIconImageView.image = UIImage(systemName: "arrow.up.circle.fill")
        case .transfer:
            typeIconImageView.image = UIImage(systemName: "arrow.left.arrow.right.circle.fill")
        }
        
        // Apply status-specific styling
        switch transaction.status {
        case .pending:
            contentView.alpha = 0.8
            descriptionLabel.textColor = .secondaryLabel
        case .cleared, .reconciled:
            contentView.alpha = 1.0
            descriptionLabel.textColor = .label
        case .cancelled:
            contentView.alpha = 0.6
            descriptionLabel.textColor = .tertiaryLabel
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset all content
        amountLabel.text = nil
        descriptionLabel.text = nil
        dateLabel.text = nil
        categoryLabel.text = nil
        typeIconImageView.image = nil
        transaction = nil
        
        // Reset styling
        contentView.alpha = 1.0
        descriptionLabel.textColor = .label
    }
}