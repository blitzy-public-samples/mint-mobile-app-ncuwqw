//
// Decimal+Extensions.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify locale settings match application requirements for currency formatting
// 2. Validate currency rounding behavior aligns with financial compliance requirements
// 3. Review percentage formatting precision requirements for different use cases

// Foundation framework - iOS 14.0+
import Foundation
import AppConstants

// Extension providing financial calculation and formatting capabilities for the Decimal type
// Implements requirements from:
// - Financial Tracking (Section 1.2): Accurate financial calculations and currency formatting
// - Budget Management (Section 1.2): Precise decimal calculations for budget tracking
// - Investment Tracking (Section 1.2): Accurate decimal calculations for investment metrics
extension Decimal {
    
    /// Returns the decimal formatted as a currency string using the default currency
    /// Implements Financial Tracking requirement for consistent currency formatting
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = AppConstants.Financial.defaultCurrency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: self as NSDecimalNumber) ?? String(describing: self)
    }
    
    /// Returns the decimal formatted as a percentage with 2 decimal places
    /// Implements Budget Management requirement for progress monitoring
    var asPercentage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        // Convert decimal to percentage by multiplying by 100
        let percentageValue = self as NSDecimalNumber
        return formatter.string(from: percentageValue) ?? "\(self)%"
    }
    
    /// Rounds the decimal to specified number of decimal places using banker's rounding
    /// Implements Financial Tracking requirement for accurate calculations
    /// - Parameter places: Number of decimal places to round to
    /// - Returns: Rounded decimal value
    func roundToPlaces(_ places: Int) -> Decimal {
        var value = self
        var rounded = Decimal()
        
        // Calculate rounding scale based on decimal places
        let scale = pow(10.0, places)
        value *= scale
        
        // Perform banker's rounding
        NSDecimalRound(&rounded, &value, 0, .bankers)
        rounded /= scale
        
        return rounded
    }
    
    /// Formats the decimal as currency with specified currency code
    /// Implements Financial Tracking requirement for flexible currency formatting
    /// - Parameter currencyCode: ISO 4217 currency code (e.g., "USD", "EUR")
    /// - Returns: Formatted currency string
    func asCurrencyWith(currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        // Handle potential formatting failures gracefully
        guard let formattedString = formatter.string(from: self as NSDecimalNumber) else {
            // Fallback to basic formatting if NumberFormatter fails
            return "\(currencyCode) \(self)"
        }
        
        return formattedString
    }
    
    /// Formats the decimal as percentage with specified decimal places
    /// Implements Budget Management and Investment Tracking requirements for flexible percentage formatting
    /// - Parameter decimalPlaces: Number of decimal places to show in formatted string
    /// - Returns: Formatted percentage string
    func asPercentageWith(decimalPlaces: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        
        // Convert to percentage value
        let percentageValue = self as NSDecimalNumber
        
        // Handle potential formatting failures gracefully
        guard let formattedString = formatter.string(from: percentageValue) else {
            // Fallback to basic formatting if NumberFormatter fails
            return String(format: "%.\(decimalPlaces)f%%", (self as NSDecimalNumber).doubleValue * 100)
        }
        
        return formattedString
    }
}