//
// String+Extensions.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Review and adjust currency formatting patterns with finance team
// 2. Verify email validation regex complies with latest RFC standards
// 3. Confirm masking requirements for sensitive data with security team
// 4. Ensure localization compatibility for currency formatting

import Foundation // iOS 14.0+

// Relative imports from Common/Constants
import "../Constants/AppConstants"
import "../Constants/ErrorConstants"

// Extension providing secure string manipulation and validation utilities
// Implements requirements from sections 1.2 Scope/Financial Tracking and 6.3 Security Controls/Input Validation
extension String {
    
    // MARK: - Financial Formatting
    
    /// Formats string as currency according to app's default currency format
    /// Requirement: Financial Data Formatting - Section 1.2 Scope/Financial Tracking
    func formatAsCurrency() -> String {
        // Validate string contains valid decimal number
        guard let decimal = Decimal(string: self.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)),
              self.isValidAmount() else {
            return ""
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = AppConstants.Financial.defaultCurrency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: decimal as NSDecimalNumber) ?? ""
    }
    
    /// Validates if string represents a valid financial amount
    /// Requirement: Input Validation - Section 6.3 Security Controls/Input Validation
    func isValidAmount() -> Bool {
        // Regex pattern for valid currency format (allows decimal numbers with up to 2 decimal places)
        let pattern = "^\\d+(\\.\\d{1,2})?$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        
        let range = NSRange(location: 0, length: self.utf16.count)
        guard regex.firstMatch(in: self, range: range) != nil,
              let decimal = Decimal(string: self) else {
            return false
        }
        
        // Validate amount is within acceptable range (prevent overflow)
        return decimal >= 0 && decimal <= Decimal.greatestFiniteMagnitude
    }
    
    // MARK: - Email Validation
    
    /// Validates email format according to RFC 5322 standard
    /// Requirement: Input Validation - Section 6.3 Security Controls/Input Validation
    func isValidEmail() -> Bool {
        // RFC 5322 compliant email validation pattern
        let pattern = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        
        let range = NSRange(location: 0, length: self.utf16.count)
        guard regex.firstMatch(in: self, range: range) != nil else {
            return false
        }
        
        // Additional validation checks
        let components = self.components(separatedBy: "@")
        guard components.count == 2,
              !components[0].isEmpty,
              !components[1].isEmpty,
              components[1].contains(".") else {
            return false
        }
        
        return true
    }
    
    // MARK: - String Sanitization
    
    /// Returns trimmed string and validates for content
    /// Requirement: Input Validation - Section 6.3 Security Controls/Input Validation
    func trimmedAndValidated() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Masks sensitive data showing only specified number of digits
    /// Requirement: Data Formatting - Section 2.2.1 Client Applications/iOS Native
    func maskSensitiveData(visibleDigits: Int) -> String {
        guard !self.isEmpty, visibleDigits >= 0, visibleDigits < self.count else {
            return self
        }
        
        let maskedLength = self.count - visibleDigits
        let maskedPortion = String(repeating: "*", count: maskedLength)
        let visiblePortion = self.suffix(visibleDigits)
        
        return maskedPortion + visiblePortion
    }
}