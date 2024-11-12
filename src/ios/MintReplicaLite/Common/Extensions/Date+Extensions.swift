//
// Date+Extensions.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify date formatting aligns with localization requirements
// 2. Review timezone handling for international deployment
// 3. Validate date calculations against fiscal calendar if different from standard calendar

// Foundation framework - iOS 14.0+
import Foundation
import Common.Constants.AppConstants

// Implements Financial Tracking, Budget Management, and Goal Management requirements
// from Section 1.2 Scope by providing date manipulation capabilities
extension Date {
    
    // MARK: - Computed Properties
    
    /// Returns date formatted as 'MMM yyyy' for budget period displays
    /// Implements Budget Management requirement for period calculations
    public var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: self)
    }
    
    /// Returns date formatted as 'MM/dd/yy' for transaction lists
    /// Implements Financial Tracking requirement for transaction date handling
    public var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: self)
    }
    
    /// Returns date formatted as 'MMMM dd, yyyy' for detailed views
    /// Implements Goal Management requirement for timeline tracking
    public var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter.string(from: self)
    }
    
    /// Indicates if date falls within current calendar month
    /// Implements Budget Management requirement for period calculations
    public var isInCurrentMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    // MARK: - Public Methods
    
    /// Returns start date of the month containing this date
    /// Implements Budget Management requirement for period calculations
    public func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        var startComponents = DateComponents()
        startComponents.year = components.year
        startComponents.month = components.month
        startComponents.day = 1
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0
        
        return calendar.date(from: startComponents) ?? self
    }
    
    /// Returns end date of the month containing this date
    /// Implements Budget Management requirement for period calculations
    public func endOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        var endComponents = DateComponents()
        endComponents.year = components.year
        endComponents.month = components.month
        endComponents.day = calendar.range(of: .day, in: .month, for: self)?.count ?? 1
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        
        return calendar.date(from: endComponents) ?? self
    }
    
    /// Calculates number of days between this date and another date
    /// Implements Goal Management requirement for timeline tracking
    public func daysBetween(_ otherDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: otherDate)
        return abs(components.day ?? 0)
    }
    
    /// Calculates number of months between this date and another date
    /// Implements Budget Management requirement for period calculations
    public func monthsBetween(_ otherDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: self, to: otherDate)
        return abs(components.month ?? 0)
    }
    
    /// Returns new date by adding specified number of months
    /// Implements Goal Management requirement for timeline tracking
    public func addingMonths(_ months: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = months
        
        return calendar.date(byAdding: components, to: self) ?? self
    }
    
    /// Checks if date falls between start and end dates inclusive
    /// Implements Financial Tracking requirement for transaction date filtering
    public func isBetween(_ startDate: Date, _ endDate: Date) -> Bool {
        return (self >= startDate) && (self <= endDate)
    }
}