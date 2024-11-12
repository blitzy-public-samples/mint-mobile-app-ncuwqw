//
// AccountListViewController.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify accessibility labels and identifiers are properly configured for VoiceOver support
// 2. Test table view scrolling performance with large account lists
// 3. Review swipe action animations and haptic feedback implementation
// 4. Validate error view layout on different screen sizes

// UIKit framework - iOS 14.0+
import UIKit
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../../../Domain/Models/Account"
import "../Presentation/Accounts/ViewModels/AccountListViewModel"
import "../Presentation/Accounts/Views/AccountCell"
import "../Presentation/Common/Views/LoadingView"
import "../Presentation/Common/Views/ErrorView"

/// View controller responsible for displaying and managing the list of financial accounts
/// Implements:
/// - Account Management (Section 1.2): Financial account aggregation with real-time updates
/// - Financial Tracking (Section 1.2): Account balance monitoring in list format
/// - UI Implementation (Section 5.1.2): Account list view following iOS HIG
final class AccountListViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        return tableView
    }()
    
    private let loadingView = LoadingView(message: "Syncing accounts...")
    private let errorView = ErrorView()
    private let refreshControl = UIRefreshControl()
    
    private let viewModel: AccountListViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewModel: AccountListViewModel) {
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
        viewModel.transform(.viewDidLoad)
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        // Configure navigation bar
        title = "Accounts"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Configure table view
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AccountCell.self, forCellReuseIdentifier: "AccountCell")
        
        // Configure refresh control
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // Configure loading and error views
        view.addSubview(loadingView)
        view.addSubview(errorView)
        errorView.isHidden = true
        
        // Setup constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func bindViewModel() {
        // Handle loading state
        viewModel.transform(.viewDidLoad)
            .sink { [weak self] output in
                switch output {
                case .loading(let isLoading):
                    if isLoading {
                        self?.loadingView.show()
                    } else {
                        self?.loadingView.hide()
                        self?.refreshControl.endRefreshing()
                    }
                    
                case .accounts(let accounts):
                    self?.errorView.isHidden = true
                    self?.tableView.reloadData()
                    
                case .error(let error):
                    self?.errorView.isHidden = false
                    self?.errorView.configure(
                        message: error.localizedDescription,
                        icon: UIImage(systemName: "exclamationmark.triangle"),
                        retryButtonTitle: "Try Again"
                    ) { [weak self] in
                        self?.viewModel.transform(.refresh)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func handleRefresh() {
        viewModel.transform(.refresh)
    }
}

// MARK: - UITableViewDataSource

extension AccountListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.accounts.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath) as? AccountCell,
              let account = viewModel.accounts.value[safe: indexPath.row] else {
            return UITableViewCell()
        }
        
        cell.configure(with: account)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AccountListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let account = viewModel.accounts.value[safe: indexPath.row] else {
            return nil
        }
        
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] (_, _, completion) in
            self?.viewModel.transform(.deleteAccount(account.id))
            completion(true)
        }
        
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}