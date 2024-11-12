// HUMAN TASKS:
// 1. Verify encryption requirements for sensitive transaction data fields
// 2. Review transaction amount rounding rules with financial compliance team
// 3. Validate transaction type enumeration covers all required transaction categories

// Foundation framework - iOS 14.0+
import Foundation

// Relative imports
import "../Models/Category"
import "../Models/Account"
import "../../Common/Extensions/Decimal+Extensions"

/// Defines the types of financial transactions
/// Requirement: Financial Tracking (1.2 Scope/Financial Tracking)
@objc public enum TransactionType: String, Codable {
    case debit
    case credit
    case transfer
}

/// Defines the possible states of a transaction
/// Requirement: Financial Tracking (1.2 Scope/Financial Tracking)
@objc public enum TransactionStatus: String, Codable {
    case pending
    case cleared
    case reconciled
    case cancelled
}

/// Represents a financial transaction in the system with secure data handling
/// Requirements addressed:
/// - Financial Tracking (1.2 Scope/Financial Tracking): Transaction management and categorization
/// - Transaction Data Security (6.2.2 Sensitive Data Handling): Secure transaction data handling
@objc public final class Transaction: NSObject, Codable, Hashable {
    
    // MARK: - Properties
    
    public let id: UUID
    public let accountId: UUID
    public private(set) var categoryId: UUID?
    public private(set) var amount: Decimal
    public private(set) var date: Date
    public let description: String
    public private(set) var notes: String?
    public let type: TransactionType
    public private(set) var status: TransactionStatus
    public private(set) var isRecurring: Bool
    public private(set) var merchantName: String?
    public let createdAt: Date
    public private(set) var updatedAt: Date
    
    // MARK: - Initialization
    
    /// Initializes a new Transaction instance with required properties
    /// Implements Financial Tracking requirement for transaction creation
    public init(
        id: UUID,
        accountId: UUID,
        amount: Decimal,
        description: String,
        type: TransactionType
    ) {
        // Validate input parameters
        precondition(!description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Transaction description cannot be empty")
        
        self.id = id
        self.accountId = accountId
        self.amount = amount.roundToPlaces(2)
        self.description = description
        self.type = type
        
        // Set default values
        self.status = .pending
        let now = Date()
        self.date = now
        self.createdAt = now
        self.updatedAt = now
        self.isRecurring = false
        
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Updates the transaction category
    /// Implements Financial Tracking requirement for transaction categorization
    public func updateCategory(_ categoryId: UUID?) {
        self.categoryId = categoryId
        self.updatedAt = Date()
    }
    
    /// Updates the transaction status
    /// Implements Financial Tracking requirement for transaction state management
    public func updateStatus(_ newStatus: TransactionStatus) {
        self.status = newStatus
        self.updatedAt = Date()
    }
    
    /// Returns formatted currency string for amount
    /// Implements Financial Tracking requirement for transaction amount formatting
    public func formattedAmount() -> String {
        let formattedAmount = amount.asCurrency
        return type == .debit ? "-\(formattedAmount)" : formattedAmount
    }
    
    // MARK: - Hashable Conformance
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable Conformance
    
    public static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Codable Conformance
    
    private enum CodingKeys: String, CodingKey {
        case id
        case accountId
        case categoryId
        case amount
        case date
        case description
        case notes
        case type
        case status
        case isRecurring
        case merchantName
        case createdAt
        case updatedAt
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        accountId = try container.decode(UUID.self, forKey: .accountId)
        categoryId = try container.decodeIfPresent(UUID.self, forKey: .categoryId)
        amount = try container.decode(Decimal.self, forKey: .amount)
        date = try container.decode(Date.self, forKey: .date)
        description = try container.decode(String.self, forKey: .description)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        type = try container.decode(TransactionType.self, forKey: .type)
        status = try container.decode(TransactionStatus.self, forKey: .status)
        isRecurring = try container.decode(Bool.self, forKey: .isRecurring)
        merchantName = try container.decodeIfPresent(String.self, forKey: .merchantName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        super.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(accountId, forKey: .accountId)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encode(amount, forKey: .amount)
        try container.encode(date, forKey: .date)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encode(isRecurring, forKey: .isRecurring)
        try container.encodeIfPresent(merchantName, forKey: .merchantName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}