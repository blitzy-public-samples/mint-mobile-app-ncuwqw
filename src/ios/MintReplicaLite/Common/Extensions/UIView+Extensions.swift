//
// UIView+Extensions.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify shadow rendering performance on target devices, especially for scrolling views
// 2. Test animation durations across different device types for optimal user experience
// 3. Validate corner radius values align with design system specifications

// UIKit framework - iOS 14.0+
import UIKit

// Internal constants for styling consistency
import Common.Constants.AppConstants

// MARK: - UIView Extension
/// Extension providing common view-related functionality used throughout the iOS app
/// Implements 'iOS Native UI Implementation' requirement from Section 1.1 System Overview
/// Implements 'UI Component Styling' requirement from Section 5.1.2 Screen Layouts
extension UIView {
    
    /// Adds a shadow to the view with customizable parameters
    /// - Parameters:
    ///   - radius: The blur radius (in points) used to render the shadow
    ///   - opacity: The opacity of the shadow (0.0 to 1.0)
    ///   - offset: The offset (in points) of the shadow from the view
    ///   - color: The color of the shadow
    func addShadow(
        radius: CGFloat,
        opacity: CGFloat,
        offset: CGFloat,
        color: UIColor
    ) {
        layer.shadowRadius = radius
        layer.shadowOpacity = Float(opacity)
        layer.shadowOffset = CGSize(width: 0, height: offset)
        layer.shadowColor = color.cgColor
        
        // Enable rasterization for better shadow performance
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    /// Rounds the corners of the view using either a specified radius or the default value
    /// - Parameter radius: Optional corner radius value. If nil, uses AppConstants.UI.defaultCornerRadius
    func roundCorners(radius: CGFloat? = nil) {
        layer.cornerRadius = radius ?? AppConstants.UI.defaultCornerRadius
        layer.masksToBounds = true
    }
    
    /// Adds a border to the view with specified width and color
    /// - Parameters:
    ///   - width: The width of the border
    ///   - color: The color of the border
    func addBorder(width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
    
    /// Animates the view's opacity from 0 to 1
    /// - Parameters:
    ///   - duration: Optional animation duration. If nil, uses AppConstants.UI.defaultAnimationDuration
    ///   - completion: Optional closure to be executed when the animation completes
    func fadeIn(
        duration: TimeInterval? = nil,
        completion: (() -> Void)? = nil
    ) {
        alpha = 0
        UIView.animate(
            withDuration: duration ?? TimeInterval(AppConstants.UI.defaultAnimationDuration),
            animations: { [weak self] in
                self?.alpha = 1.0
            },
            completion: { _ in
                completion?()
            }
        )
    }
    
    /// Animates the view's opacity from 1 to 0
    /// - Parameters:
    ///   - duration: Optional animation duration. If nil, uses AppConstants.UI.defaultAnimationDuration
    ///   - completion: Optional closure to be executed when the animation completes
    func fadeOut(
        duration: TimeInterval? = nil,
        completion: (() -> Void)? = nil
    ) {
        alpha = 1
        UIView.animate(
            withDuration: duration ?? TimeInterval(AppConstants.UI.defaultAnimationDuration),
            animations: { [weak self] in
                self?.alpha = 0.0
            },
            completion: { _ in
                completion?()
            }
        )
    }
    
    /// Adds multiple subviews to the view in a single call
    /// - Parameter views: Array of UIView objects to be added as subviews
    func addSubviews(_ views: [UIView]) {
        views.forEach { addSubview($0) }
    }
}