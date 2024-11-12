//
// InvestmentUseCase.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Review error handling strategy with team
// 2. Set up monitoring for portfolio calculation performance
// 3. Validate portfolio metrics calculation formulas with finance team
// 4. Configure Combine publisher memory management strategy

// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Relative imports
import "../Domain/Models/Investment"
import "../Data/Repositories/InvestmentRepository"

/// Value type containing portfolio performance metrics
/// Implements Investment Tracking requirement (Section 1.2) for performance tracking
struct PortfolioMetrics {
    let totalValue: Decimal
    let totalReturn: Decimal
    let returnPercentage: Decimal
    let numberOfInvestments: Int
}

/// Implements business logic for investment portfolio management with reactive updates
/// Implements Investment Tracking requirement (Section 1.2) for portfolio monitoring
final class InvestmentUseCase {
    
    // MARK: - Properties
    
    private let repository: InvestmentRepository
    let investmentUpdatePublisher = PassthroughSubject<Investment, Error>()
    
    // MARK: - Initialization
    
    init(repository: InvestmentRepository) {
        self.repository = repository
    }
    
    // MARK: - Portfolio Management
    
    /// Retrieves investment portfolio for an account
    /// Implements Investment Tracking requirement for portfolio monitoring
    func getPortfolio(accountId: UUID) -> AnyPublisher<[Investment], Error> {
        Future<[Investment], Error> { promise in
            let investments = self.repository.getInvestments(accountId: accountId)
            promise(.success(investments))
        }
        .eraseToAnyPublisher()
    }
    
    /// Adds a new investment to the portfolio
    /// Implements Investment Tracking requirement for portfolio updates
    func addInvestment(investment: Investment) -> AnyPublisher<Investment, Error> {
        Future<Investment, Error> { promise in
            let result = self.repository.saveInvestment(investment: investment)
            switch result {
            case .success(let savedInvestment):
                self.investmentUpdatePublisher.send(savedInvestment)
                promise(.success(savedInvestment))
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Updates investment price and recalculates values
    /// Implements Investment Tracking requirement for real-time price updates
    func updateInvestmentPrice(investmentId: UUID, newPrice: Decimal) -> AnyPublisher<Investment, Error> {
        Future<Investment, Error> { promise in
            guard newPrice > 0 else {
                promise(.failure(NSError(domain: "InvestmentUseCase",
                                      code: 400,
                                      userInfo: [NSLocalizedDescriptionKey: "Price must be greater than zero"])))
                return
            }
            
            let result = self.repository.updateInvestmentPrice(id: investmentId, newPrice: newPrice)
            switch result {
            case .success(let updatedInvestment):
                self.investmentUpdatePublisher.send(updatedInvestment)
                promise(.success(updatedInvestment))
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Updates investment shares and cost basis
    /// Implements Investment Tracking requirement for portfolio updates
    func updateInvestmentShares(investmentId: UUID, newShares: Decimal, newCostBasis: Decimal) -> AnyPublisher<Investment, Error> {
        Future<Investment, Error> { promise in
            guard newShares > 0 else {
                promise(.failure(NSError(domain: "InvestmentUseCase",
                                      code: 400,
                                      userInfo: [NSLocalizedDescriptionKey: "Shares must be greater than zero"])))
                return
            }
            
            guard newCostBasis >= 0 else {
                promise(.failure(NSError(domain: "InvestmentUseCase",
                                      code: 400,
                                      userInfo: [NSLocalizedDescriptionKey: "Cost basis cannot be negative"])))
                return
            }
            
            guard let investment = self.repository.getInvestment(id: investmentId) else {
                promise(.failure(NSError(domain: "InvestmentUseCase",
                                      code: 404,
                                      userInfo: [NSLocalizedDescriptionKey: "Investment not found"])))
                return
            }
            
            investment.updateShares(newShares, newCostBasis: newCostBasis)
            
            let result = self.repository.saveInvestment(investment: investment)
            switch result {
            case .success(let updatedInvestment):
                self.investmentUpdatePublisher.send(updatedInvestment)
                promise(.success(updatedInvestment))
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Removes an investment from the portfolio
    /// Implements Investment Tracking requirement for portfolio management
    func removeInvestment(investmentId: UUID) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            let result = self.repository.deleteInvestment(id: investmentId)
            switch result {
            case .success:
                promise(.success(()))
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Calculates portfolio performance metrics
    /// Implements Investment Tracking requirement for performance metrics
    func calculatePortfolioMetrics(accountId: UUID) -> AnyPublisher<PortfolioMetrics, Error> {
        Future<PortfolioMetrics, Error> { promise in
            let investments = self.repository.getInvestments(accountId: accountId)
            
            let totalValue = investments.reduce(Decimal.zero) { $0 + $1.currentValue }
            let totalReturn = investments.reduce(Decimal.zero) { $0 + $1.returnAmount }
            
            let returnPercentage: Decimal
            if totalValue - totalReturn > 0 {
                returnPercentage = ((totalReturn / (totalValue - totalReturn)) * 100).rounded(2)
            } else {
                returnPercentage = 0
            }
            
            let metrics = PortfolioMetrics(
                totalValue: totalValue.rounded(2),
                totalReturn: totalReturn.rounded(2),
                returnPercentage: returnPercentage,
                numberOfInvestments: investments.count
            )
            
            promise(.success(metrics))
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Decimal Extensions

private extension Decimal {
    func rounded(_ places: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, places, .plain)
        return result
    }
}