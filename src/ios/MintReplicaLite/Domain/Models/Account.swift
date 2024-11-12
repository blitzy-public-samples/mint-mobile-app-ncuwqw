//
// Account.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify encryption requirements for accountNumber storage
// 2. Review balance rounding rules with financial compliance team
// 3. Confirm institution ID format requirements
// 4. Validate account type enumeration covers all required account categories

// Foundation framework - iOS 14.0+
import Foundation

// Relative import for currency formatting extensions
import "../../../Common/Extensions/Decimal+Extensions"

// MARK: - AccountType Enum
/// Defines supported financial account types
/// Implements Account Management requirement (Section 1.2) for account classification
enum AccountType: String, Codable {
    case checking
    case savings
    case credit
    case investment
    case loan
    case other
}

// MARK: - Account Class
/// Core domain model representing a financial account
/// Implements:
/// - Account Management (Section 1.2): Financial account aggregation
/// - Financial Tracking (Section 1.2): Balance monitoring and updates
/// - Data Security (Section 2.4): Secure account data handling
@objc final class Account: NSObject, Codable, Hashable {
    
    // MARK: - Properties
    let id: UUID
    let name: String
    let institutionId: String
    let accountNumber: String
    let type: AccountType
    private(set) var balance: Decimal
    private(set) var isActive: Bool
    private(set) var lastSyncDate: Date
    let createdAt: Date
    private(set) var updatedAt: Date
    
    // MARK: - Initialization
    /// Initializes a new financial account with required properties
    /// Implements Account Management requirement for account creation
    init(id: UUID,
         name: String,
         institutionId: String,
         accountNumber: String,
         type: AccountType,
         balance: Decimal) {
        
        // Validate required fields
        precondition(!name.isEmpty, "Account name cannot be empty")
        precondition(!institutionId.isEmpty, "Institution ID cannot be empty")
        precondition(!accountNumber.isEmpty, "Account number cannot be empty")
        
        self.id = id
        self.name = name
        self.institutionId = institutionId
        self.accountNumber = accountNumber
        self.type = type
        self.balance = balance.roundToPlaces(2)
        self.isActive = true
        
        let now = Date()
        self.lastSyncDate = now
        self.createdAt = now
        self.updatedAt = now
        
        super.init()
    }
    
    // MARK: - Public Methods
    /// Updates account balance with synchronization tracking
    /// Implements Financial Tracking requirement for balance monitoring
    func updateBalance(_ newBalance: Decimal) {
        balance = newBalance.roundToPlaces(2)
        lastSyncDate = Date()
        updatedAt = lastSyncDate
    }
    
    /// Returns formatted currency string for the account balance
    /// Implements Financial Tracking requirement for currency formatting
    func formattedBalance() -> String {
        return balance.asCurrency
    }
    
    /// Toggles account active status
    /// Implements Account Management requirement for account status control
    func toggleActive() {
        isActive.toggle()
        updatedAt = Date()
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable Conformance
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Codable Conformance
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case institutionId
        case accountNumber
        case type
        case balance
        case isActive
        case lastSyncDate
        case createdAt
        case updatedAt
    }
}