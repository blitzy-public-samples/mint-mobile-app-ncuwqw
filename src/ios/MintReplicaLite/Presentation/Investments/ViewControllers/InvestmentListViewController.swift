//
// InvestmentListViewController.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify table view cell reuse performance with large datasets
// 2. Test pull-to-refresh behavior with slow network conditions
// 3. Validate accessibility labels and VoiceOver support
// 4. Review error view retry action user experience

// UIKit framework - iOS 14.0+
import UIKit
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../../../Presentation/Common/Views/LoadingView"
import "../../../Presentation/Common/Views/ErrorView"
import "../ViewModels/InvestmentListViewModel"
import "../Views/InvestmentCell"

/// View controller responsible for displaying and managing the investment portfolio list screen
/// Implements:
/// - Investment Tracking (1.2): Basic portfolio monitoring and investment account integration
/// - Client Architecture (2.2.1): MVVM pattern implementation with Combine
/// - UI Implementation (5.1.6): Investment list view following iOS HIG
final class InvestmentListViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let viewModel: InvestmentListViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.register(InvestmentCell.self, forCellReuseIdentifier: "InvestmentCell")
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refreshControl
    }()
    
    private lazy var loadingView: LoadingView = {
        let view = LoadingView(message: "Loading investments...")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var errorView: ErrorView = {
        let view = ErrorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Publishers
    
    private let loadPortfolioSubject = PassthroughSubject<UUID, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private let investmentSelectionSubject = PassthroughSubject<Investment, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewModel: InvestmentListViewModel) {
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
        configureTableView()
        bindViewModel()
        
        // Trigger initial portfolio load
        // Implements Investment Tracking requirement for portfolio monitoring
        loadPortfolioSubject.send(UUID())
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        // Configure navigation bar
        title = "Investments"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Add and configure subviews
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(loadingView)
        view.addSubview(errorView)
        tableView.refreshControl = refreshControl
        
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
            
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func bindViewModel() {
        // Create input from subjects
        let input = InvestmentListViewModel.Input(
            loadPortfolioTrigger: loadPortfolioSubject.eraseToAnyPublisher(),
            refreshTrigger: refreshSubject.eraseToAnyPublisher(),
            investmentSelection: investmentSelectionSubject.eraseToAnyPublisher()
        )
        
        // Transform input to output
        let output = viewModel.transform(input)
        
        // Bind investments to table view updates
        output.investments
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
                    self?.loadingView.show()
                } else {
                    self?.loadingView.hide()
                }
            }
            .store(in: &cancellables)
        
        // Bind error state
        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.errorView.configure(
                        message: error.localizedDescription,
                        icon: UIImage(systemName: "exclamationmark.triangle"),
                        retryButtonTitle: "Try Again"
                    ) { [weak self] in
                        self?.loadPortfolioSubject.send(UUID())
                    }
                    self.errorView.show()
                } else {
                    self.errorView.hide()
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func handleRefresh() {
        refreshSubject.send()
    }
}

// MARK: - UITableViewDataSource

extension InvestmentListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.investments.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "InvestmentCell",
            for: indexPath
        ) as? InvestmentCell else {
            return UITableViewCell()
        }
        
        let investment = viewModel.investments.value[indexPath.row]
        cell.configure(with: investment)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension InvestmentListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let investment = viewModel.investments.value[indexPath.row]
        investmentSelectionSubject.send(investment)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}