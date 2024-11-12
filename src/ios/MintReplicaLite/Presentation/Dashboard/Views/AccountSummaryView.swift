//
// AccountSummaryView.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify shadow and animation performance on target devices with large account lists
// 2. Review accessibility labels and traits for VoiceOver support
// 3. Validate color contrast ratios meet WCAG guidelines
// 4. Test dynamic type scaling for all text elements

// UIKit framework - iOS 14.0+
import UIKit

// Relative imports for internal dependencies
import "../../../Domain/Models/Account"
import "../../../Common/Extensions/UIView+Extensions"
import "../../../Common/Extensions/Decimal+Extensions"

/// A custom view that displays a summary of user's financial accounts with real-time updates
/// Implements:
/// - Account Management (Section 1.2): Real-time balance updates and financial account aggregation
/// - UI Component Design (Section 5.1.2): Account summary card with balance information and styling
@IBDesignable
class AccountSummaryView: UIView {
    
    // MARK: - Properties
    
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fill
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let totalBalanceLabel: UILabel = {
        let label = UILabel()
        label.text = "Total Balance"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let totalBalanceAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let accountsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var accounts: [Account] = []
    private var isAnimating: Bool = false
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Add and configure container stack view
        addSubview(containerStackView)
        
        // Add total balance section
        let balanceContainer = UIStackView()
        balanceContainer.axis = .vertical
        balanceContainer.spacing = 8
        balanceContainer.addArrangedSubview(totalBalanceLabel)
        balanceContainer.addArrangedSubview(totalBalanceAmountLabel)
        
        containerStackView.addArrangedSubview(balanceContainer)
        containerStackView.addArrangedSubview(accountsStackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        // Apply styling
        addShadow(radius: 8, opacity: 0.1, offset: 4, color: .black)
        roundCorners(radius: 12)
    }
    
    // MARK: - Public Methods
    
    /// Updates the view with new account data and animates changes
    /// Implements Account Management requirement for real-time balance updates
    func updateAccounts(_ newAccounts: [Account]) {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Store new accounts
        self.accounts = newAccounts
        
        // Calculate and update total balance
        let totalBalance = newAccounts.reduce(Decimal.zero) { $0 + $1.balance }
        totalBalanceAmountLabel.text = totalBalance.asCurrency
        
        // Animate account views update
        accountsStackView.fadeOut { [weak self] in
            guard let self = self else { return }
            
            // Remove existing account views
            self.accountsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            // Add new account views
            for account in newAccounts {
                let accountView = self.createAccountItemView(account)
                self.accountsStackView.addArrangedSubview(accountView)
            }
            
            // Animate new views
            self.accountsStackView.fadeIn { [weak self] in
                self?.isAnimating = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createAccountItemView(_ account: Account) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Account name label
        let nameLabel = UILabel()
        nameLabel.text = account.name
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Account balance label
        let balanceLabel = UILabel()
        balanceLabel.text = account.formattedBalance()
        balanceLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        balanceLabel.textColor = .label
        balanceLabel.textAlignment = .right
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Account type icon
        let typeImageView = UIImageView()
        typeImageView.contentMode = .scaleAspectFit
        typeImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set icon based on account type
        switch account.type {
        case .checking:
            typeImageView.image = UIImage(systemName: "dollarsign.circle.fill")
        case .savings:
            typeImageView.image = UIImage(systemName: "banknote.fill")
        case .credit:
            typeImageView.image = UIImage(systemName: "creditcard.fill")
        case .investment:
            typeImageView.image = UIImage(systemName: "chart.line.uptrend.xyaxis")
        case .loan:
            typeImageView.image = UIImage(systemName: "hand.wave.fill")
        case .other:
            typeImageView.image = UIImage(systemName: "building.columns.fill")
        }
        typeImageView.tintColor = .secondaryLabel
        
        // Add subviews
        container.addSubviews([typeImageView, nameLabel, balanceLabel])
        
        // Setup constraints
        NSLayoutConstraint.activate([
            typeImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            typeImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            typeImageView.widthAnchor.constraint(equalToConstant: 24),
            typeImageView.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.leadingAnchor.constraint(equalTo: typeImageView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            balanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 12),
            balanceLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            balanceLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Apply styling
        container.backgroundColor = .secondarySystemBackground
        container.roundCorners(radius: 8)
        
        return container
    }
}