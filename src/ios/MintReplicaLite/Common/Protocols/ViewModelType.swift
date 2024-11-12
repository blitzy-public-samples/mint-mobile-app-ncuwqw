//
// ViewModelType.swift
// MintReplicaLite
//
// Human Tasks:
// - Ensure minimum iOS deployment target is set to iOS 14.0+ in project settings
// - Verify Combine framework is properly linked in the project
//
// Third-party Dependencies:
// - Foundation (iOS 14.0+)
// - Combine (iOS 14.0+)

import Foundation
import Combine

/// Protocol defining the core interface for implementing MVVM pattern with reactive data binding
/// Requirements addressed:
/// - Client Applications Architecture (2.2.1): MVVM architecture pattern implementation
/// - Data Flow Architecture (2.3): Standardized data flow between view and view model layers
/// - iOS Platform Architecture (4.2.1): Combine framework integration for reactive programming
protocol ViewModelType {
    /// Type representing input data and events from the view layer
    /// Examples include:
    /// - User interactions (button taps, text input)
    /// - View lifecycle events (viewDidAppear, viewWillDisappear)
    /// - Data refresh triggers
    associatedtype Input
    
    /// Type representing transformed data ready for view consumption
    /// Examples include:
    /// - View state updates
    /// - Formatted data models for display
    /// - Navigation commands
    associatedtype Output
    
    /// Transforms view input into output data using Combine publishers
    /// - Parameter input: The input data or events from the view layer
    /// - Returns: The transformed output data stream for view consumption
    ///
    /// Implementation guidelines:
    /// - Use Combine operators for data transformation
    /// - Keep transformation logic pure and testable
    /// - Handle errors appropriately in the transformation chain
    /// - Emit results through Combine publishers
    func transform(_ input: Input) -> Output
}