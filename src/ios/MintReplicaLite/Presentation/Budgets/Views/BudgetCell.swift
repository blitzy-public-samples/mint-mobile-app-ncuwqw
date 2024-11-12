// HUMAN TASKS:
// 1. Verify accessibility labels and hints meet VoiceOver requirements
// 2. Review color contrast ratios for progress bar and alert indicators
// 3. Test cell reuse performance with large datasets

// UIKit framework - iOS 14.0+
import UIKit

// Internal imports with relative paths
import "../../../Domain/Models/Budget"
import "../../../Common/Extensions/UIView+Extensions"
import "../../../Common/Extensions/Decimal+Extensions"

/// Custom table view cell for displaying budget information with progress visualization
/// Requirements addressed:
/// - Budget Management (1.2 Scope/Budget Management): Category-based budgeting display
/// - Progress Monitoring (1.2 Scope/Budget Management): Visual progress tracking
/// - UI Component Design (5.1.2 Screen Layouts): Consistent styling
@IBDesignable
final class BudgetCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var spentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var progressBar: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemGreen
        progress.trackTintColor = .systemGray5
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private lazy var alertIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        imageView.tintColor = .systemOrange
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Properties
    
    private var budget: Budget?
    
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
        // Add subviews
        contentView.addSubviews([
            categoryLabel,
            amountLabel,
            spentLabel,
            progressBar,
            alertIcon
        ])
        
        // Apply styling
        contentView.addShadow(
            radius: 4,
            opacity: 0.1,
            offset: 2,
            color: .black
        )
        contentView.roundCorners(radius: 8)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            categoryLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            categoryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryLabel.trailingAnchor.constraint(equalTo: alertIcon.leadingAnchor, constant: -8),
            
            alertIcon.centerYAnchor.constraint(equalTo: categoryLabel.centerYAnchor),
            alertIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            alertIcon.widthAnchor.constraint(equalToConstant: 20),
            alertIcon.heightAnchor.constraint(equalToConstant: 20),
            
            amountLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 8),
            amountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            spentLabel.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor),
            spentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            progressBar.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 12),
            progressBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            progressBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            progressBar.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        // Set background
        backgroundColor = .clear
        contentView.backgroundColor = .systemBackground
        
        // Remove default selection style
        selectionStyle = .none
    }
    
    // MARK: - Configuration
    
    /// Configures the cell with budget data
    /// - Parameter budget: Budget model containing the information to display
    func configure(with budget: Budget) {
        self.budget = budget
        
        categoryLabel.text = budget.category?.name
        amountLabel.text = budget.amount.asCurrency
        spentLabel.text = budget.spent.asCurrency
        progressBar.progress = Float(budget.getProgress())
        
        // Update progress bar color based on progress
        let progress = budget.getProgress()
        progressBar.progressTintColor = progress > 0.9 ? .systemRed :
                                      progress > 0.7 ? .systemOrange :
                                      .systemGreen
        
        alertIcon.isHidden = !budget.shouldAlert()
        
        // Configure accessibility
        categoryLabel.accessibilityLabel = "Category"
        categoryLabel.accessibilityValue = budget.category?.name
        
        amountLabel.accessibilityLabel = "Budget amount"
        amountLabel.accessibilityValue = budget.amount.asCurrency
        
        spentLabel.accessibilityLabel = "Amount spent"
        spentLabel.accessibilityValue = budget.spent.asCurrency
        
        progressBar.accessibilityLabel = "Budget progress"
        progressBar.accessibilityValue = "\(Int(progress * 100))% used"
        
        alertIcon.accessibilityLabel = "Budget alert"
        alertIcon.accessibilityHint = "Budget threshold exceeded"
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        categoryLabel.text = nil
        amountLabel.text = nil
        spentLabel.text = nil
        progressBar.progress = 0
        alertIcon.isHidden = true
        budget = nil
        
        // Reset accessibility
        [categoryLabel, amountLabel, spentLabel, progressBar, alertIcon].forEach {
            $0.accessibilityLabel = nil
            $0.accessibilityValue = nil
            $0.accessibilityHint = nil
        }
    }
}