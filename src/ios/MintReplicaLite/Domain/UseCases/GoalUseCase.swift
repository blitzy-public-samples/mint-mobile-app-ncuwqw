//
// GoalUseCase.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify error tracking integration is properly configured
// 2. Review logging implementation for production monitoring
// 3. Ensure proper analytics events are being tracked
// 4. Validate goal amount thresholds with business requirements

// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Internal imports
import "../Models/Goal"
import "../../Data/Repositories/GoalRepository"
import "../../Common/Constants/ErrorConstants"

// Implements requirement: Goal Management (1.2 Scope/Goal Management)
public protocol GoalUseCaseProtocol {
    func createGoal(name: String, type: GoalType, targetAmount: Decimal, targetDate: Date) -> AnyPublisher<Goal, Error>
    func updateGoalProgress(goalId: UUID, amount: Decimal) -> AnyPublisher<Goal, Error>
    func linkAccountToGoal(goalId: UUID, accountId: UUID) -> AnyPublisher<Goal, Error>
    func fetchGoals() -> AnyPublisher<[Goal], Error>
    func deleteGoal(goalId: UUID) -> AnyPublisher<Void, Error>
}

// Implements requirements:
// - Goal Management (1.2 Scope/Goal Management)
// - Cross-platform Data Synchronization (1.1 System Overview/Client Applications)
public final class GoalUseCase: GoalUseCaseProtocol {
    
    // MARK: - Properties
    
    private let repository: GoalRepositoryProtocol
    
    // MARK: - Initialization
    
    public init(repository: GoalRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - GoalUseCaseProtocol Implementation
    
    public func createGoal(name: String, type: GoalType, targetAmount: Decimal, targetDate: Date) -> AnyPublisher<Goal, Error> {
        return Future<Goal, Error> { promise in
            // Validate name
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                promise(.failure(ErrorConstants.ValidationError.invalidGoal))
                return
            }
            
            // Validate target amount
            guard targetAmount > 0 else {
                promise(.failure(ErrorConstants.ValidationError.invalidAmount))
                return
            }
            
            // Validate target date
            guard targetDate > Date() else {
                promise(.failure(ErrorConstants.ValidationError.invalidDate))
                return
            }
            
            do {
                // Create new goal instance
                let goal = try Goal(name: name, type: type, targetAmount: targetAmount, targetDate: targetDate)
                
                // Save goal using repository
                let result = self.repository.createGoal(goal)
                switch result {
                case .success(let createdGoal):
                    promise(.success(createdGoal))
                case .failure(let error):
                    promise(.failure(error))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func updateGoalProgress(goalId: UUID, amount: Decimal) -> AnyPublisher<Goal, Error> {
        return Future<Goal, Error> { promise in
            // Validate amount
            guard amount >= 0 else {
                promise(.failure(ErrorConstants.ValidationError.invalidAmount))
                return
            }
            
            // Fetch goal
            let fetchResult = self.repository.fetchGoal(id: goalId)
            switch fetchResult {
            case .success(let goal):
                guard let goal = goal else {
                    promise(.failure(ErrorConstants.DataError.notFound))
                    return
                }
                
                do {
                    // Update goal progress
                    try goal.updateProgress(amount: amount)
                    
                    // Save updated goal
                    let updateResult = self.repository.updateGoal(goal)
                    switch updateResult {
                    case .success(let updatedGoal):
                        promise(.success(updatedGoal))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                } catch {
                    promise(.failure(error))
                }
                
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func linkAccountToGoal(goalId: UUID, accountId: UUID) -> AnyPublisher<Goal, Error> {
        return Future<Goal, Error> { promise in
            // Fetch goal
            let fetchResult = self.repository.fetchGoal(id: goalId)
            switch fetchResult {
            case .success(let goal):
                guard let goal = goal else {
                    promise(.failure(ErrorConstants.DataError.notFound))
                    return
                }
                
                // Link account
                if goal.linkAccount(accountId) {
                    // Save updated goal
                    let updateResult = self.repository.updateGoal(goal)
                    switch updateResult {
                    case .success(let updatedGoal):
                        promise(.success(updatedGoal))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                } else {
                    promise(.failure(ErrorConstants.DataError.invalidData))
                }
                
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func fetchGoals() -> AnyPublisher<[Goal], Error> {
        return Future<[Goal], Error> { promise in
            let result = self.repository.fetchAllGoals()
            switch result {
            case .success(let goals):
                promise(.success(goals))
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func deleteGoal(goalId: UUID) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            let result = self.repository.deleteGoal(id: goalId)
            switch result {
            case .success:
                promise(.success(()))
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}