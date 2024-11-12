//
// Investment.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify price update frequency requirements with product team
// 2. Review performance calculation formulas with financial team
// 3. Confirm decimal rounding rules for investment calculations
// 4. Validate supported investment types list is complete

// Foundation framework - iOS 14.0+
import Foundation

// Relative imports
import "../../../Common/Extensions/Decimal+Extensions"
import "./Account"

// MARK: - InvestmentType Enum
/// Defines supported investment types in the system
/// Implements Investment Tracking requirement (Section 1.2) for investment classification
enum InvestmentType: String, Codable {
    case stock
    case etf
    case mutualFund
    case bond
    case other
}

// MARK: - Investment Class
/// Core domain model representing an investment holding with real-time price tracking
/// Implements:
/// - Investment Tracking (Section 1.2): Portfolio monitoring and performance metrics
@objc final class Investment: NSObject, Codable, Hashable {
    
    // MARK: - Properties
    let id: UUID
    let accountId: UUID
    let symbol: String
    let name: String
    let type: InvestmentType
    private(set) var shares: Decimal
    private(set) var costBasis: Decimal
    private(set) var currentPrice: Decimal
    private(set) var currentValue: Decimal
    private(set) var returnAmount: Decimal
    private(set) var returnPercentage: Decimal
    private(set) var lastUpdated: Date
    let purchaseDate: Date
    let createdAt: Date
    private(set) var updatedAt: Date
    
    // MARK: - Initialization
    /// Initializes a new investment holding with validation and calculations
    /// Implements Investment Tracking requirement for portfolio monitoring
    init(id: UUID,
         accountId: UUID,
         symbol: String,
         name: String,
         type: InvestmentType,
         shares: Decimal,
         costBasis: Decimal,
         currentPrice: Decimal) {
        
        // Validate required fields
        precondition(!symbol.isEmpty, "Investment symbol cannot be empty")
        precondition(!name.isEmpty, "Investment name cannot be empty")
        precondition(shares > 0, "Shares must be greater than zero")
        precondition(costBasis >= 0, "Cost basis cannot be negative")
        precondition(currentPrice >= 0, "Current price cannot be negative")
        
        self.id = id
        self.accountId = accountId
        self.symbol = symbol
        self.name = name
        self.type = type
        
        // Round decimal values for precision
        self.shares = shares.roundToPlaces(6)
        self.costBasis = costBasis.roundToPlaces(2)
        self.currentPrice = currentPrice.roundToPlaces(2)
        
        // Calculate initial values
        self.currentValue = (shares * currentPrice).roundToPlaces(2)
        self.returnAmount = (self.currentValue - costBasis).roundToPlaces(2)
        self.returnPercentage = costBasis > 0 ? 
            ((self.returnAmount / costBasis) * 100).roundToPlaces(2) : 0
        
        let now = Date()
        self.lastUpdated = now
        self.purchaseDate = now
        self.createdAt = now
        self.updatedAt = now
        
        super.init()
    }
    
    // MARK: - Public Methods
    /// Updates current price and recalculates performance metrics
    /// Implements Investment Tracking requirement for real-time price updates
    func updatePrice(_ newPrice: Decimal) {
        precondition(newPrice >= 0, "Price cannot be negative")
        
        currentPrice = newPrice.roundToPlaces(2)
        currentValue = (shares * currentPrice).roundToPlaces(2)
        returnAmount = (currentValue - costBasis).roundToPlaces(2)
        returnPercentage = costBasis > 0 ? 
            ((returnAmount / costBasis) * 100).roundToPlaces(2) : 0
        
        let now = Date()
        lastUpdated = now
        updatedAt = now
    }
    
    /// Updates shares and cost basis with recalculation of metrics
    /// Implements Investment Tracking requirement for portfolio updates
    func updateShares(_ newShares: Decimal, newCostBasis: Decimal) {
        precondition(newShares > 0, "Shares must be greater than zero")
        precondition(newCostBasis >= 0, "Cost basis cannot be negative")
        
        shares = newShares.roundToPlaces(6)
        costBasis = newCostBasis.roundToPlaces(2)
        
        currentValue = (shares * currentPrice).roundToPlaces(2)
        returnAmount = (currentValue - costBasis).roundToPlaces(2)
        returnPercentage = costBasis > 0 ? 
            ((returnAmount / costBasis) * 100).roundToPlaces(2) : 0
        
        updatedAt = Date()
    }
    
    /// Returns formatted currency string for current value
    /// Implements Investment Tracking requirement for value formatting
    func formattedCurrentValue() -> String {
        return currentValue.asCurrency
    }
    
    /// Returns formatted return amount and percentage
    /// Implements Investment Tracking requirement for performance metrics
    func formattedReturn() -> String {
        return "\(returnAmount.asCurrency) (\(returnPercentage.asPercentage))"
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable Conformance
    static func == (lhs: Investment, rhs: Investment) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Codable Conformance
    private enum CodingKeys: String, CodingKey {
        case id
        case accountId
        case symbol
        case name
        case type
        case shares
        case costBasis
        case currentPrice
        case currentValue
        case returnAmount
        case returnPercentage
        case lastUpdated
        case purchaseDate
        case createdAt
        case updatedAt
    }
}