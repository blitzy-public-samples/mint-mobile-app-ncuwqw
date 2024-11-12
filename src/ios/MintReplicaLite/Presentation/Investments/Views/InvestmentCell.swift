//
// InvestmentCell.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify shadow rendering performance in table view scrolling
// 2. Confirm color scheme compliance with design system
// 3. Validate accessibility label formatting with UX team

// UIKit framework - iOS 14.0+
import UIKit

// Relative imports
import "../../../Domain/Models/Investment"
import "../../../Common/Extensions/UIView+Extensions"
import "../../../Common/Extensions/Decimal+Extensions"

// MARK: - InvestmentCell
/// Custom UITableViewCell for displaying investment information with styled layout
/// Implements:
/// - Investment Tracking requirement (Section 1.2): Basic portfolio monitoring display
/// - UI Component Design requirement (Section 5.1.2): Investment list item styling
@IBDesignable
final class InvestmentCell: UITableViewCell {
    
    // MARK: - UI Components
    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let currentValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let returnLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Properties
    private var investment: Investment?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.Style, reuseIdentifier: String?) {
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
        
        // Create left stack view for symbol and name
        let leftStackView = UIStackView()
        leftStackView.axis = .vertical
        leftStackView.spacing = 4
        leftStackView.addArrangedSubview(symbolLabel)
        leftStackView.addArrangedSubview(nameLabel)
        
        // Create right stack view for value and return
        let rightStackView = UIStackView()
        rightStackView.axis = .vertical
        rightStackView.spacing = 4
        rightStackView.addArrangedSubview(currentValueLabel)
        rightStackView.addArrangedSubview(returnLabel)
        
        // Add stack views to main content stack
        contentStackView.addArrangedSubview(leftStackView)
        contentStackView.addArrangedSubview(rightStackView)
        
        // Add content stack view to cell
        contentView.addSubview(contentStackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        
        // Apply styling using UIView+Extensions
        contentView.roundCorners(radius: 8)
        contentView.addShadow(
            radius: 4,
            opacity: 0.1,
            offset: 2,
            color: .black
        )
    }
    
    // MARK: - Configuration
    /// Configures the cell with investment data
    /// Implements Investment Tracking requirement for performance metrics display
    func configure(with investment: Investment) {
        self.investment = investment
        
        // Update labels with investment data
        symbolLabel.text = investment.symbol
        nameLabel.text = investment.name
        currentValueLabel.text = investment.formattedCurrentValue()
        returnLabel.text = investment.formattedReturn()
        
        // Set return label color based on return amount
        returnLabel.textColor = investment.returnAmount >= 0 ? .systemGreen : .systemRed
        
        // Update accessibility
        updateAccessibility(with: investment)
    }
    
    // MARK: - Accessibility
    private func updateAccessibility(with investment: Investment) {
        // Set accessibility label combining all relevant information
        accessibilityLabel = "\(investment.symbol) \(investment.name), Current value: \(investment.formattedCurrentValue()), Return: \(investment.formattedReturn())"
        accessibilityTraits = .updatesFrequently
        isAccessibilityElement = true
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset all labels
        symbolLabel.text = nil
        nameLabel.text = nil
        currentValueLabel.text = nil
        returnLabel.text = nil
        
        // Reset colors to default
        returnLabel.textColor = .label
        
        // Clear investment reference
        investment = nil
    }
}