//
// DashboardViewController.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify Auto Layout constraints on different iOS device sizes
// 2. Test VoiceOver accessibility support for all UI elements
// 3. Review memory usage with large datasets in production
// 4. Validate pull-to-refresh behavior with slow network conditions

// Third-party Dependencies:
// - UIKit (iOS 14.0+)
// - Combine (iOS 14.0+)

import UIKit
import Combine

/// Main view controller for the dashboard screen implementing MVVM pattern
/// Requirements addressed:
/// - Account Management (1.2 Scope/Account Management): Display real-time balance updates
/// - Financial Tracking (1.2 Scope/Financial Tracking): Show automated transaction import
/// - Budget Management (1.2 Scope/Budget Management): Display budget progress monitoring
/// - Dashboard Layout (5.1 User Interface Design/5.1.2 Dashboard Layout): Comprehensive dashboard view
final class DashboardViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let viewModel: DashboardViewModel
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private let accountSummaryView: AccountSummaryView = {
        let view = AccountSummaryView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let budgetSummaryView: BudgetSummaryView = {
        let view = BudgetSummaryView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        
        // Initial data load
        refreshData()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        // Configure view controller
        view.backgroundColor = .systemBackground
        title = "Dashboard"
        
        // Add scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(containerStackView)
        
        // Add refresh control
        scrollView.refreshControl = refreshControl
        
        // Add summary views to container
        containerStackView.addArrangedSubview(accountSummaryView)
        containerStackView.addArrangedSubview(budgetSummaryView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container stack view constraints
            containerStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Summary view height constraints
            accountSummaryView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            budgetSummaryView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
        
        // Configure accessibility
        configureAccessibility()
    }
    
    private func configureAccessibility() {
        scrollView.accessibilityLabel = "Dashboard content"
        scrollView.accessibilityHint = "Scroll to view all dashboard information"
        
        accountSummaryView.accessibilityLabel = "Account summary"
        accountSummaryView.accessibilityTraits = .updatesFrequently
        
        budgetSummaryView.accessibilityLabel = "Budget summary"
        budgetSummaryView.accessibilityTraits = .updatesFrequently
        
        refreshControl.accessibilityLabel = "Refresh dashboard"
        refreshControl.accessibilityHint = "Pull down to refresh all dashboard data"
    }
    
    private func bindViewModel() {
        // Create input from refresh control
        let input = DashboardViewModel.Input(
            refreshTrigger: refreshControl.publisher(for: .valueChanged)
                .map { _ in }
                .eraseToAnyPublisher()
        )
        
        // Transform input to output
        let output = viewModel.transform(input)
        
        // Bind accounts data to account summary view
        output.accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accounts in
                self?.accountSummaryView.updateAccounts(accounts)
            }
            .store(in: &cancellables)
        
        // Bind budget data to budget summary view
        output.budgetProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] budgetProgress in
                if let firstBudget = budgetProgress.first {
                    self?.budgetSummaryView.configure(with: firstBudget.0)
                }
            }
            .store(in: &cancellables)
        
        // Handle refresh control
        output.accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)
    }
    
    @objc private func refreshData() {
        viewModel.refreshDashboard()
    }
}