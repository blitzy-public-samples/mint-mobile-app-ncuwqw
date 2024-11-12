// HUMAN TASKS:
// 1. Verify that UIKit and Combine frameworks are properly linked in project settings
// 2. Ensure minimum iOS deployment target is set to iOS 14.0+
// 3. Review accessibility labels and hints with the UX team
// 4. Test table view scroll performance with large datasets

// UIKit framework - iOS 14.0+
import UIKit
// Combine framework - iOS 14.0+
import Combine

// Internal imports with relative paths
import "../../../Domain/Models/Budget"
import "../ViewModels/BudgetListViewModel"
import "../Views/BudgetCell"

/// View controller responsible for displaying and managing the list of budgets
/// Requirements addressed:
/// - Category-based budgeting (1.2 Scope/Budget Management): Budget list display and management
/// - Progress monitoring (1.2 Scope/Budget Management): Real-time budget progress tracking
/// - UI Component Design (5.1 User Interface Design/5.1.2 Screen Layouts): iOS native layout implementation
@objc final class BudgetListViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: BudgetListViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 120
        table.delegate = self
        table.dataSource = self
        table.register(BudgetCell.self, forCellReuseIdentifier: "BudgetCell")
        return table
    }()
    
    private lazy var periodFilter: UISegmentedControl = {
        let items = ["Monthly", "Quarterly", "Annual"]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        return control
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var addButton: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addBudgetTapped)
        )
    }()
    
    // MARK: - Initialization
    
    init(viewModel: BudgetListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        bindViewModel()
        
        // Initial data load
        let input = BudgetListViewModel.Input(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            periodSelected: periodFilter.publisher(for: \.selectedSegmentIndex)
                .map { index -> String? in
                    switch index {
                    case 0: return "monthly"
                    case 1: return "quarterly"
                    case 2: return "annual"
                    default: return nil
                    }
                }
                .eraseToAnyPublisher(),
            deleteBudget: PassthroughSubject<UUID, Never>().eraseToAnyPublisher()
        )
        
        let output = viewModel.transform(input)
        bindViewModelOutput(output)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(periodFilter)
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            periodFilter.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            periodFilter.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            periodFilter.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: periodFilter.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Setup accessibility
        periodFilter.accessibilityLabel = "Budget period filter"
        periodFilter.accessibilityHint = "Select budget period to display"
        tableView.accessibilityLabel = "Budgets list"
    }
    
    private func setupNavigationBar() {
        title = "Budgets"
        navigationItem.rightBarButtonItem = addButton
        navigationItem.largeTitleDisplayMode = .always
    }
    
    // MARK: - View Model Binding
    
    private func bindViewModelOutput(_ output: BudgetListViewModel.Output) {
        // Bind budgets updates to table view
        output.budgets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        // Bind loading state
        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        // Bind error messages
        output.error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(message: error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func addBudgetTapped() {
        // Navigation to budget creation will be handled by the coordinator
        // Implementing navigation is out of scope for this file
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BudgetListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.budgets.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "BudgetCell",
            for: indexPath
        ) as? BudgetCell else {
            return UITableViewCell()
        }
        
        let budget = viewModel.budgets.value[indexPath.row]
        cell.configure(with: budget)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BudgetListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Budget detail navigation will be handled by the coordinator
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let budget = viewModel.budgets.value[indexPath.row]
        
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] _, _, completion in
            self?.viewModel.deleteBudget(budgetId: budget.id)
            completion(true)
        }
        
        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}