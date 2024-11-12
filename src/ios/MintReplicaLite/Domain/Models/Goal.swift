//
// Goal.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify that Core Data model matches this implementation if Core Data integration is needed
// 2. Review currency formatting locale settings for different regions
// 3. Validate goal amount validation rules with business requirements
// 4. Ensure proper error handling and logging integration

// Foundation framework - iOS 14.0+
import Foundation

// Implements requirement: Cross-platform Data Synchronization (1.1 System Overview/Client Applications)
// Enum representing different types of financial goals
@objc public enum GoalType: Int, Codable, Equatable {
    case savings
    case debt
    case investment
    case emergency
    case retirement
    case custom
}

// Implements requirement: Goal Management (1.2 Scope/Goal Management)
// Enum representing the current status of a goal
@objc public enum GoalStatus: Int, Codable, Equatable {
    case notStarted
    case inProgress
    case completed
    case onHold
}

// Implements requirements:
// - Goal Management (1.2 Scope/Goal Management)
// - Cross-platform Data Synchronization (1.1 System Overview/Client Applications)
@objc public class Goal: NSObject, Codable, Equatable {
    // MARK: - Properties
    
    public let id: UUID
    public var name: String
    public var goalDescription: String
    public var type: GoalType
    public var targetAmount: Decimal
    public var currentAmount: Decimal
    public var targetDate: Date
    public var startDate: Date
    public var linkedAccountIds: Set<UUID>
    public var isActive: Bool
    
    // MARK: - Computed Properties
    
    public var progress: Decimal {
        guard targetAmount > 0 else { return 0 }
        let ratio = currentAmount / targetAmount
        let percentage = ratio * 100
        return min(max(percentage.roundToPlaces(2), 0), 100)
    }
    
    public var remainingAmount: Decimal {
        max(targetAmount - currentAmount, 0)
    }
    
    public var status: GoalStatus {
        if !isActive {
            return .onHold
        }
        if currentAmount >= targetAmount {
            return .completed
        }
        if currentAmount > 0 {
            return .inProgress
        }
        return .notStarted
    }
    
    public var formattedTargetAmount: String {
        targetAmount.asCurrency
    }
    
    public var formattedCurrentAmount: String {
        currentAmount.asCurrency
    }
    
    public var formattedProgress: String {
        progress.asPercentage
    }
    
    // MARK: - Initialization
    
    public init(name: String, type: GoalType, targetAmount: Decimal, targetDate: Date) throws {
        // Validate name
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GoalError.invalidName("Goal name cannot be empty")
        }
        guard name.count <= 100 else {
            throw GoalError.invalidName("Goal name cannot exceed 100 characters")
        }
        
        // Validate target amount
        guard targetAmount > 0 else {
            throw GoalError.invalidAmount("Target amount must be greater than zero")
        }
        
        // Validate target date
        guard targetDate > Date() else {
            throw GoalError.invalidDate("Target date must be in the future")
        }
        
        self.id = UUID()
        self.name = name
        self.goalDescription = ""
        self.type = type
        self.targetAmount = targetAmount
        self.currentAmount = 0
        self.targetDate = targetDate
        self.startDate = Date()
        self.linkedAccountIds = Set<UUID>()
        self.isActive = true
        
        super.init()
    }
    
    // MARK: - Public Methods
    
    public func updateProgress(amount: Decimal) throws {
        guard amount >= 0 else {
            throw GoalError.invalidAmount("Amount cannot be negative")
        }
        
        currentAmount = min(amount, targetAmount)
    }
    
    public func linkAccount(_ accountId: UUID) -> Bool {
        guard !linkedAccountIds.contains(accountId) else {
            return false
        }
        linkedAccountIds.insert(accountId)
        return true
    }
    
    public func unlinkAccount(_ accountId: UUID) -> Bool {
        guard linkedAccountIds.contains(accountId) else {
            return false
        }
        linkedAccountIds.remove(accountId)
        return true
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: Goal, rhs: Goal) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Error Handling
    
    private enum GoalError: LocalizedError {
        case invalidName(String)
        case invalidAmount(String)
        case invalidDate(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidName(let message),
                 .invalidAmount(let message),
                 .invalidDate(let message):
                return message
            }
        }
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case goalDescription
        case type
        case targetAmount
        case currentAmount
        case targetDate
        case startDate
        case linkedAccountIds
        case isActive
    }
}