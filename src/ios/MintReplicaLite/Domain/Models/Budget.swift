// HUMAN TASKS:
// 1. Verify that the alert threshold values align with business requirements
// 2. Review currency formatting locale settings for different regions
// 3. Validate budget period calculations across fiscal calendars

// Foundation framework - iOS 14.0+
import Foundation

// Internal imports with relative paths
import "../Models/Category"
import "../../Common/Extensions/Decimal+Extensions"

/// Defines available budget period types for financial planning
/// Requirement: Category-based budgeting (1.2 Scope/Budget Management)
@objc public enum BudgetPeriod: String, Codable {
    case monthly
    case quarterly
    case annual
}

/// Represents a budget allocation for a specific category with tracking and alert capabilities
/// Requirements addressed:
/// - Category-based budgeting (1.2 Scope/Budget Management)
/// - Progress monitoring (1.2 Scope/Budget Management)
/// - Customizable alerts (1.2 Scope/Budget Management)
@objc public final class Budget: NSObject, Codable {
    // MARK: - Properties
    
    /// Unique identifier for the budget
    public let id: UUID
    
    /// Associated category identifier
    public let categoryId: UUID
    
    /// Allocated budget amount
    public private(set) var amount: Decimal
    
    /// Current spent amount
    public private(set) var spent: Decimal
    
    /// Budget period type
    public let period: BudgetPeriod
    
    /// Alert threshold percentage (0.0 to 1.0)
    public private(set) var alertThreshold: Double
    
    /// Flag indicating if alerts are enabled
    public private(set) var alertEnabled: Bool
    
    /// Budget period start date
    public let startDate: Date
    
    /// Budget period end date
    public let endDate: Date
    
    /// Timestamp when the budget was created
    public let createdAt: Date
    
    /// Timestamp when the budget was last updated
    public private(set) var updatedAt: Date
    
    // MARK: - Initialization
    
    /// Initializes a new Budget instance with specified parameters
    /// - Parameters:
    ///   - id: Unique identifier for the budget
    ///   - categoryId: Associated category identifier
    ///   - amount: Allocated budget amount
    ///   - period: Budget period type
    ///   - alertThreshold: Alert threshold percentage (0.0 to 1.0)
    ///   - alertEnabled: Flag indicating if alerts are enabled
    ///   - startDate: Budget period start date
    ///   - endDate: Budget period end date
    public init(id: UUID,
               categoryId: UUID,
               amount: Decimal,
               period: BudgetPeriod,
               alertThreshold: Double,
               alertEnabled: Bool,
               startDate: Date,
               endDate: Date) throws {
        // Validate input parameters
        guard amount > 0 else {
            throw NSError(domain: "BudgetError",
                         code: 4001,
                         userInfo: [NSLocalizedDescriptionKey: "Budget amount must be greater than zero"])
        }
        
        guard alertThreshold > 0 && alertThreshold <= 1.0 else {
            throw NSError(domain: "BudgetError",
                         code: 4002,
                         userInfo: [NSLocalizedDescriptionKey: "Alert threshold must be between 0 and 1"])
        }
        
        guard startDate < endDate else {
            throw NSError(domain: "BudgetError",
                         code: 4003,
                         userInfo: [NSLocalizedDescriptionKey: "Start date must be before end date"])
        }
        
        self.id = id
        self.categoryId = categoryId
        self.amount = amount
        self.period = period
        self.alertThreshold = alertThreshold
        self.alertEnabled = alertEnabled
        self.startDate = startDate
        self.endDate = endDate
        self.spent = 0
        self.createdAt = Date()
        self.updatedAt = Date()
        
        super.init()
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case id
        case categoryId
        case amount
        case spent
        case period
        case alertThreshold
        case alertEnabled
        case startDate
        case endDate
        case createdAt
        case updatedAt
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        categoryId = try container.decode(UUID.self, forKey: .categoryId)
        amount = try container.decode(Decimal.self, forKey: .amount)
        spent = try container.decode(Decimal.self, forKey: .spent)
        period = try container.decode(BudgetPeriod.self, forKey: .period)
        alertThreshold = try container.decode(Double.self, forKey: .alertThreshold)
        alertEnabled = try container.decode(Bool.self, forKey: .alertEnabled)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        super.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(amount, forKey: .amount)
        try container.encode(spent, forKey: .spent)
        try container.encode(period, forKey: .period)
        try container.encode(alertThreshold, forKey: .alertThreshold)
        try container.encode(alertEnabled, forKey: .alertEnabled)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Public Methods
    
    /// Updates the spent amount for budget tracking
    /// Requirement: Progress monitoring (1.2 Scope/Budget Management)
    /// - Parameter newAmount: New spent amount to record
    public func updateSpent(_ newAmount: Decimal) throws {
        guard newAmount >= 0 else {
            throw NSError(domain: "BudgetError",
                         code: 4004,
                         userInfo: [NSLocalizedDescriptionKey: "Spent amount cannot be negative"])
        }
        
        spent = newAmount
        updatedAt = Date()
    }
    
    /// Calculates remaining budget amount
    /// Requirement: Progress monitoring (1.2 Scope/Budget Management)
    /// - Returns: Remaining budget amount formatted as currency
    public func getRemainingAmount() -> String {
        let remaining = amount - spent
        return remaining.asCurrency
    }
    
    /// Calculates budget utilization percentage
    /// Requirement: Progress monitoring (1.2 Scope/Budget Management)
    /// - Returns: Budget utilization percentage
    public func getProgress() -> Double {
        guard amount > 0 else { return 0.0 }
        return Double(truncating: (spent / amount) as NSNumber)
    }
    
    /// Checks if budget threshold alert should trigger
    /// Requirement: Customizable alerts (1.2 Scope/Budget Management)
    /// - Returns: True if alert threshold is exceeded
    public func shouldAlert() -> Bool {
        guard alertEnabled else { return false }
        return getProgress() >= alertThreshold
    }
    
    // MARK: - NSObject Overrides
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Budget else { return false }
        return self.id == other.id
    }
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }
    
    public override var description: String {
        return "Budget(id: \(id), categoryId: \(categoryId), amount: \(amount.asCurrency), spent: \(spent.asCurrency), period: \(period), progress: \(getProgress().asPercentage))"
    }
}