// HUMAN TASKS:
// 1. Verify that progress animation durations match UX requirements
// 2. Review accessibility labels and VoiceOver support
// 3. Validate color scheme with design system for different progress states

// UIKit framework - iOS 14.0+
import UIKit

// Internal imports with relative paths
import "../../../Domain/Models/Budget"
import "../../../Common/Extensions/UIView+Extensions"
import "../../../Common/Extensions/Decimal+Extensions"

/// A custom view that displays budget summary information with animated progress visualization
/// Requirements addressed:
/// - Budget Management (1.2 Scope/Budget Management): Progress monitoring and budget vs. actual reporting
/// - Dashboard Layout (5.1.2 Screen Layouts): Budget Summary component with progress visualization
/// - Real-time Updates (3.2 Performance Requirements): Immediate visual feedback
@IBDesignable
final class BudgetSummaryView: UIView {
    
    // MARK: - Private Properties
    
    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    @IBOutlet private weak var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.text = "Budget Summary"
        label.textColor = .label
        return label
    }()
    
    @IBOutlet private weak var progressView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    @IBOutlet private weak var spentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    @IBOutlet private weak var remainingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    @IBOutlet private weak var budgetProgress: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.trackTintColor = .systemGray5
        progress.progressTintColor = .systemGreen
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        return progress
    }()
    
    private var budget: Budget?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Add and configure container stack
        addSubview(containerStack)
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        // Add components to stack
        containerStack.addArrangedSubview(titleLabel)
        containerStack.addArrangedSubview(progressView)
        containerStack.addArrangedSubview(spentLabel)
        containerStack.addArrangedSubview(remainingLabel)
        containerStack.addArrangedSubview(budgetProgress)
        
        // Configure progress view height
        budgetProgress.heightAnchor.constraint(equalToConstant: 8).isActive = true
        
        // Apply styling
        roundCorners(radius: 12)
        addShadow(radius: 4, opacity: 0.1, offset: 2, color: .black)
        
        // Set initial state
        spentLabel.text = Decimal(0).asCurrency
        remainingLabel.text = "Remaining: \(Decimal(0).asCurrency)"
        budgetProgress.progress = 0
        
        // Configure accessibility
        isAccessibilityElement = false
        titleLabel.accessibilityTraits = .header
        spentLabel.accessibilityLabel = "Spent amount"
        remainingLabel.accessibilityLabel = "Remaining amount"
        budgetProgress.accessibilityLabel = "Budget progress"
    }
    
    private func updateProgressColor(for progress: Double) {
        let color: UIColor
        switch progress {
        case 0..<0.7:
            color = .systemGreen
        case 0.7..<0.9:
            color = .systemYellow
        default:
            color = .systemRed
        }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.budgetProgress.progressTintColor = color
        }
    }
    
    // MARK: - Public Methods
    
    /// Configures the view with budget data and updates the visualization
    /// - Parameter budget: The budget model containing the data to display
    func configure(with budget: Budget) {
        self.budget = budget
        
        // Update labels
        spentLabel.text = budget.spent.asCurrency
        remainingLabel.text = "Remaining: \(budget.getRemainingAmount())"
        
        // Update progress
        updateProgress()
        
        // Update accessibility
        let progress = budget.getProgress()
        let percentage = (progress * 100).rounded()
        budgetProgress.accessibilityValue = "\(Int(percentage))% of budget used"
        
        // Apply alert styling if needed
        if budget.shouldAlert() {
            spentLabel.textColor = .systemRed
        } else {
            spentLabel.textColor = .label
        }
    }
    
    private func updateProgress() {
        guard let budget = budget else { return }
        
        let progress = Float(budget.getProgress())
        
        // Animate progress update
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
            self?.budgetProgress.setProgress(progress, animated: true)
            self?.updateProgressColor(for: Double(progress))
        }
    }
}