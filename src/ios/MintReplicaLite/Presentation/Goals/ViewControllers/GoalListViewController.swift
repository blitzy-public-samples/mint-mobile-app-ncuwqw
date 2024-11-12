//
// GoalListViewController.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify that Interface Builder connections are properly set up if using storyboards
// 2. Ensure accessibility labels and traits are configured for VoiceOver support
// 3. Test empty state view with different screen sizes and orientations
// 4. Validate color schemes for dark mode compatibility

// UIKit framework - iOS 14.0+
import UIKit
// Combine framework - iOS 14.0+
import Combine

// Internal imports
import "../ViewModels/GoalListViewModel"
import "../Views/GoalCell"
import "../../Common/Views/EmptyStateView"

// Implements requirements:
// - Goal Management (1.2 Scope/Goal Management)
// - UI Implementation (5.1 User Interface Design/5.1.2 Screen Layouts)
// - Client Applications Architecture (2.2.1 Client Applications)
final class GoalListViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: GoalListViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.register(GoalCell.self, forCellReuseIdentifier: "GoalCell")
        return tableView
    }()
    
    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .systemBlue
        return refreshControl
    }()
    
    // MARK: - Initialization
    
    init(viewModel: GoalListViewModel) {
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
        setupBindings()
        
        // Initial data load
        viewModel.transform(.loadTrigger)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Configure navigation bar
        title = "Goals"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addGoalTapped)
        )
        navigationItem.rightBarButtonItem = addButton
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        
        // Configure refresh control
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(
            self,
            action: #selector(refreshData),
            for: .valueChanged
        )
        
        // Configure empty state
        emptyStateView.configure(
            image: UIImage(systemName: "target"),
            title: "No Goals Yet",
            message: "Start setting up your financial goals to track your progress",
            buttonTitle: "Add Goal"
        ) { [weak self] _ in
            self?.addGoalTapped()
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        // Bind goals data to table view updates
        viewModel.transform(.loadTrigger).goals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] goals in
                self?.tableView.reloadData()
                self?.emptyStateView.isHidden = !goals.isEmpty
                self?.tableView.isHidden = goals.isEmpty
            }
            .store(in: &cancellables)
        
        // Bind loading state to refresh control
        viewModel.transform(.loadTrigger).isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
        
        // Bind error handling
        viewModel.transform(.loadTrigger).error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func addGoalTapped() {
        // Navigation to goal creation will be handled by coordinator pattern
        // This is a placeholder for the implementation
    }
    
    @objc private func refreshData() {
        viewModel.transform(.loadTrigger)
    }
    
    // MARK: - Error Handling
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension GoalListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Get goals count from view model's output
        let output = viewModel.transform(.loadTrigger)
        var count = 0
        
        output.goals
            .receive(on: DispatchQueue.main)
            .sink { goals in
                count = goals.count
            }
            .store(in: &cancellables)
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "GoalCell",
            for: indexPath
        ) as? GoalCell else {
            return UITableViewCell()
        }
        
        // Configure cell with goal data
        let output = viewModel.transform(.loadTrigger)
        output.goals
            .receive(on: DispatchQueue.main)
            .sink { goals in
                if indexPath.row < goals.count {
                    cell.configure(with: goals[indexPath.row])
                }
            }
            .store(in: &cancellables)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension GoalListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Handle goal selection
        let output = viewModel.transform(.loadTrigger)
        output.goals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] goals in
                if indexPath.row < goals.count {
                    self?.viewModel.transform(.selectGoal(goals[indexPath.row]))
                }
            }
            .store(in: &cancellables)
    }
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        // Create delete action
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] _, _, completion in
            let output = self?.viewModel.transform(.loadTrigger)
            output?.goals
                .receive(on: DispatchQueue.main)
                .sink { goals in
                    if indexPath.row < goals.count {
                        self?.viewModel.transform(.deleteGoal(goals[indexPath.row].id))
                    }
                }
                .store(in: &(self?.cancellables ?? Set<AnyCancellable>()))
            completion(true)
        }
        
        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}