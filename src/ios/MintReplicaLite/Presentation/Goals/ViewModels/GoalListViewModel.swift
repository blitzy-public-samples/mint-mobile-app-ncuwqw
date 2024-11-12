//
// GoalListViewModel.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify Combine framework is properly linked in the project settings
// 2. Ensure minimum iOS deployment target is set to iOS 14.0+
// 3. Review error handling and logging integration
// 4. Validate analytics tracking implementation for goal-related events

// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Internal imports
import "../../../Domain/Models/Goal"
import "../../../Domain/UseCases/GoalUseCase"
import "../../../Common/Protocols/ViewModelType"

// Implements requirement: Client Applications Architecture (2.2.1 Client Applications)
// Input events that the view model can handle
enum GoalListViewModelInput {
    case loadTrigger
    case selectGoal(Goal)
    case deleteGoal(UUID)
}

// Implements requirement: Client Applications Architecture (2.2.1 Client Applications)
// Output data streams that the view can observe
struct GoalListViewModelOutput {
    let goals: AnyPublisher<[Goal], Never>
    let selectedGoal: AnyPublisher<Goal, Never>
    let isLoading: AnyPublisher<Bool, Never>
    let error: AnyPublisher<Error?, Never>
}

// Implements requirements:
// - Goal Management (1.2 Scope/Goal Management)
// - Cross-platform Data Synchronization (1.1 System Overview/Client Applications)
// - Client Applications Architecture (2.2.1 Client Applications)
final class GoalListViewModel: ViewModelType {
    // MARK: - Properties
    
    private let useCase: GoalUseCaseProtocol
    private let goals = CurrentValueSubject<[Goal], Never>([])
    private let selectedGoal = PassthroughSubject<Goal, Never>()
    private let isLoading = CurrentValueSubject<Bool, Never>(false)
    private let error = CurrentValueSubject<Error?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(useCase: GoalUseCaseProtocol) {
        self.useCase = useCase
    }
    
    // MARK: - ViewModelType Implementation
    
    func transform(_ input: GoalListViewModelInput) -> GoalListViewModelOutput {
        // Handle different input events
        switch input {
        case .loadTrigger:
            fetchGoals()
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.error.send(error)
                        }
                        self?.isLoading.send(false)
                    },
                    receiveValue: { [weak self] goals in
                        self?.goals.send(goals)
                    }
                )
                .store(in: &cancellables)
            
        case .selectGoal(let goal):
            selectedGoal.send(goal)
            
        case .deleteGoal(let goalId):
            deleteGoal(goalId: goalId)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.error.send(error)
                        }
                        self?.isLoading.send(false)
                    },
                    receiveValue: { [weak self] _ in
                        // Remove the deleted goal from the current list
                        if let currentGoals = self?.goals.value {
                            let updatedGoals = currentGoals.filter { $0.id != goalId }
                            self?.goals.send(updatedGoals)
                        }
                    }
                )
                .store(in: &cancellables)
        }
        
        // Return output streams
        return GoalListViewModelOutput(
            goals: goals.eraseToAnyPublisher(),
            selectedGoal: selectedGoal.eraseToAnyPublisher(),
            isLoading: isLoading.eraseToAnyPublisher(),
            error: error.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    
    private func fetchGoals() -> AnyPublisher<[Goal], Error> {
        isLoading.send(true)
        error.send(nil)
        
        return useCase.fetchGoals()
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error.send(error)
                    }
                    self?.isLoading.send(false)
                }
            )
            .eraseToAnyPublisher()
    }
    
    private func deleteGoal(goalId: UUID) -> AnyPublisher<Void, Error> {
        isLoading.send(true)
        error.send(nil)
        
        return useCase.deleteGoal(goalId: goalId)
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error.send(error)
                    }
                    self?.isLoading.send(false)
                }
            )
            .eraseToAnyPublisher()
    }
}