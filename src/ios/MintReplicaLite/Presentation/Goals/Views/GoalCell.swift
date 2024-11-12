//
// GoalCell.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify that Interface Builder connections match the IBOutlet property names
// 2. Review accessibility labels and traits for VoiceOver support
// 3. Validate color schemes with design system for dark mode compatibility

// UIKit framework - iOS 14.0+
import UIKit

// Internal imports
import Domain.Models.Goal
import Common.Extensions.UIView_Extensions

// Implements requirements:
// - Goal Management (1.2 Scope/Goal Management)
// - UI Component Design (5.1 User Interface Design/5.1.2 Screen Layouts)
@IBDesignable
class GoalCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.tintColor = .systemGreen
        progressView.trackTintColor = .systemGray5
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        return progressView
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    
    private var goal: Goal?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        applyStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        applyStyle()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        
        contentView.addSubviews([
            titleLabel,
            amountLabel,
            progressBar,
            percentageLabel,
            statusLabel
        ])
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            
            statusLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            statusLabel.heightAnchor.constraint(equalToConstant: 24),
            
            amountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            amountLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            progressBar.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 12),
            progressBar.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: percentageLabel.leadingAnchor, constant: -12),
            progressBar.heightAnchor.constraint(equalToConstant: 6),
            
            percentageLabel.centerYAnchor.constraint(equalTo: progressBar.centerYAnchor),
            percentageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            percentageLabel.widthAnchor.constraint(equalToConstant: 50),
            
            contentView.bottomAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 12)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with goal: Goal) {
        self.goal = goal
        
        titleLabel.text = goal.name
        amountLabel.text = "\(goal.formattedCurrentAmount) of \(goal.formattedTargetAmount)"
        progressBar.progress = Float(goal.progress) / 100
        percentageLabel.text = goal.formattedProgress
        
        let status = goal.status
        statusLabel.text = {
            switch status {
            case .notStarted: return "Not Started"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .onHold: return "On Hold"
            }
        }()
        
        // Apply status-specific styling
        switch status {
        case .notStarted:
            statusLabel.backgroundColor = .systemGray6
            statusLabel.textColor = .secondaryLabel
            progressBar.tintColor = .systemGray
        case .inProgress:
            statusLabel.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            statusLabel.textColor = .systemBlue
            progressBar.tintColor = .systemBlue
        case .completed:
            statusLabel.backgroundColor = .systemGreen.withAlphaComponent(0.1)
            statusLabel.textColor = .systemGreen
            progressBar.tintColor = .systemGreen
        case .onHold:
            statusLabel.backgroundColor = .systemOrange.withAlphaComponent(0.1)
            statusLabel.textColor = .systemOrange
            progressBar.tintColor = .systemOrange
        }
        
        setNeedsLayout()
    }
    
    // MARK: - Styling
    
    private func applyStyle() {
        contentView.roundCorners(radius: 12)
        contentView.addShadow(
            radius: 4,
            opacity: 0.1,
            offset: 2,
            color: .black
        )
        
        // Add padding to the cell
        contentView.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add internal padding to the cell
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        goal = nil
        titleLabel.text = nil
        amountLabel.text = nil
        progressBar.progress = 0
        percentageLabel.text = nil
        statusLabel.text = nil
    }
}