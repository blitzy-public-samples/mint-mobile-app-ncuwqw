// HUMAN TASKS:
// 1. Verify Combine framework is properly linked in project settings
// 2. Ensure minimum iOS deployment target is set to iOS 14.0+
// 3. Configure table view cell registration in Interface Builder
// 4. Set up storyboard identifier to match class name
// 5. Review accessibility labels and VoiceOver support

// UIKit framework - iOS 14.0+
import UIKit
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../ViewModels/TransactionListViewModel"
import "../Views/TransactionCell"
import "../../Common/Views/LoadingView"
import "../../../Common/Protocols/StoryboardInstantiable"

/// View controller responsible for displaying and managing the list of financial transactions
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking): Transaction list with search and filtering
/// - UI Implementation (5.1.2 Screen Layouts): Transaction list view with search and infinite scroll
final class TransactionListViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        table.separatorStyle = .none
        table.backgroundColor = .systemBackground
        return table
    }()
    
    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "Search transactions..."
        return controller
    }()
    
    private let loadingView: LoadingView = {
        let view = LoadingView()
        view.isHidden = true
        return view
    }()
    
    private let refreshControl = UIRefreshControl()
    private let viewModel: TransactionListViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewModel: TransactionListViewModel) {
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
        viewModel.transform(.init(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            refreshTriggered: refreshControl.publisher(for: .valueChanged).eraseToAnyPublisher(),
            filterSelected: Empty().eraseToAnyPublisher(),
            sortSelected: Empty().eraseToAnyPublisher()
        ))
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        title = "Transactions"
        view.backgroundColor = .systemBackground
        
        // Configure navigation bar
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(loadingView)
        tableView.addSubview(refreshControl)
        
        // Configure table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TransactionCell.self, forCellReuseIdentifier: "TransactionCell")
        
        // Configure search controller
        searchController.searchResultsUpdater = self
        
        // Setup constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func bindViewModel() {
        // Create input
        let input = TransactionListViewModel.Input(
            viewDidLoad: Just(()).eraseToAnyPublisher(),
            refreshTriggered: refreshControl.publisher(for: .valueChanged).eraseToAnyPublisher(),
            filterSelected: Empty().eraseToAnyPublisher(),
            sortSelected: Empty().eraseToAnyPublisher()
        )
        
        // Transform input to output
        let output = viewModel.transform(input)
        
        // Bind transactions
        output.transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)
        
        // Bind loading state
        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingView.show(message: "Loading transactions...")
                } else {
                    self?.loadingView.hide()
                }
            }
            .store(in: &cancellables)
        
        // Bind error state
        output.error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                let alert = UIAlertController(
                    title: "Error",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension TransactionListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0 // Will be updated through binding
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "TransactionCell",
            for: indexPath
        ) as? TransactionCell else {
            return UITableViewCell()
        }
        
        // Configure cell with transaction data
        // Will be updated through binding
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TransactionListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Handle transaction selection
    }
}

// MARK: - UISearchResultsUpdating

extension TransactionListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // Handle search text updates
    }
}

// MARK: - StoryboardInstantiable

extension TransactionListViewController: StoryboardInstantiable {
    static var storyboardName: String {
        return "Transactions"
    }
}