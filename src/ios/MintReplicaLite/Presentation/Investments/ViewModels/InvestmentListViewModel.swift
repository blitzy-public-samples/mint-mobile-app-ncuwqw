//
// InvestmentListViewModel.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify Combine memory management and subscription lifecycle
// 2. Review error handling and user feedback strategy
// 3. Validate portfolio metrics display format with UX team
// 4. Configure analytics tracking for investment list interactions

// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../../../Common/Protocols/ViewModelType"
import "../../../Domain/Models/Investment"
import "../../../Domain/UseCases/InvestmentUseCase"

/// ViewModel implementation for investment list screen with reactive data binding
/// Implements:
/// - Investment Tracking (1.2): Portfolio monitoring and performance metrics
/// - Client Architecture (2.2.1): MVVM pattern implementation
final class InvestmentListViewModel: ViewModelType {
    
    // MARK: - Input Definition
    
    struct Input {
        /// Trigger to load portfolio data for a specific account
        let loadPortfolioTrigger: AnyPublisher<UUID, Never>
        /// Trigger to refresh portfolio data
        let refreshTrigger: AnyPublisher<Void, Never>
        /// Selected investment for detail view navigation
        let investmentSelection: AnyPublisher<Investment, Never>
    }
    
    // MARK: - Output Definition
    
    struct Output {
        /// Current list of investments
        let investments: AnyPublisher<[Investment], Never>
        /// Portfolio performance metrics
        let portfolioMetrics: AnyPublisher<PortfolioMetrics?, Never>
        /// Loading state indicator
        let isLoading: AnyPublisher<Bool, Never>
        /// Error state publisher
        let error: AnyPublisher<Error?, Never>
    }
    
    // MARK: - Private Properties
    
    private let useCase: InvestmentUseCase
    private let investments = CurrentValueSubject<[Investment], Never>([])
    private let portfolioMetrics = CurrentValueSubject<PortfolioMetrics?, Never>(nil)
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(useCase: InvestmentUseCase) {
        self.useCase = useCase
        
        // Subscribe to real-time investment updates
        useCase.investmentUpdatePublisher
            .sink { [weak self] updatedInvestment in
                guard let self = self else { return }
                var currentInvestments = self.investments.value
                if let index = currentInvestments.firstIndex(where: { $0.id == updatedInvestment.id }) {
                    currentInvestments[index] = updatedInvestment
                    self.investments.send(currentInvestments)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - ViewModelType Implementation
    
    func transform(_ input: Input) -> Output {
        // Handle portfolio loading
        input.loadPortfolioTrigger
            .sink { [weak self] accountId in
                self?.loadPortfolio(accountId: accountId)
            }
            .store(in: &cancellables)
        
        // Handle refresh trigger
        input.refreshTrigger
            .compactMap { [weak self] _ in
                self?.investments.value.first?.accountId
            }
            .sink { [weak self] accountId in
                self?.loadPortfolio(accountId: accountId)
            }
            .store(in: &cancellables)
        
        // Create error publisher that resets after 5 seconds
        let errorPublisher = errorSubject
            .map { Optional($0) }
            .merge(with: errorSubject
                .delay(for: .seconds(5), scheduler: DispatchQueue.main)
                .map { _ in nil }
            )
            .eraseToAnyPublisher()
        
        return Output(
            investments: investments.eraseToAnyPublisher(),
            portfolioMetrics: portfolioMetrics.eraseToAnyPublisher(),
            isLoading: loadingSubject.eraseToAnyPublisher(),
            error: errorPublisher
        )
    }
    
    // MARK: - Private Methods
    
    /// Loads investment portfolio data and metrics
    /// Implements Investment Tracking requirement for portfolio monitoring
    private func loadPortfolio(accountId: UUID) {
        loadingSubject.send(true)
        
        useCase.getPortfolio(accountId: accountId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.loadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self.errorSubject.send(error)
                    }
                },
                receiveValue: { [weak self] investments in
                    guard let self = self else { return }
                    self.investments.send(investments)
                    self.loadPortfolioMetrics(accountId: accountId)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Loads portfolio performance metrics
    /// Implements Investment Tracking requirement for performance metrics
    private func loadPortfolioMetrics(accountId: UUID) {
        useCase.calculatePortfolioMetrics(accountId: accountId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error)
                    }
                },
                receiveValue: { [weak self] metrics in
                    self?.portfolioMetrics.send(metrics)
                }
            )
            .store(in: &cancellables)
    }
}