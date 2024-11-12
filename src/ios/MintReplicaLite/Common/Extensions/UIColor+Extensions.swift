//
// UIColor+Extensions.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify color values match design system specifications
// 2. Confirm accessibility compliance for color contrast ratios
// 3. Test color appearance in both light and dark modes
// 4. Validate color values against brand guidelines

// UIKit framework - iOS 14.0+
import UIKit
import AppConstants

// MARK: - UIColor Extension
extension UIColor {
    
    // MARK: - Theme Colors
    
    /// Primary brand color with dynamic light/dark mode support
    /// Implements Cross-platform UI Consistency requirement (Section 2.2.1)
    static var primary: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "#4CAF50", alpha: 1.0) // Green shade for dark mode
            default:
                return UIColor(hex: "#2E7D32", alpha: 1.0) // Darker green for light mode
            }
        }
    }
    
    /// Secondary brand color with dynamic light/dark mode support
    /// Implements Cross-platform UI Consistency requirement (Section 2.2.1)
    static var secondary: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "#90CAF9", alpha: 1.0) // Light blue for dark mode
            default:
                return UIColor(hex: "#1976D2", alpha: 1.0) // Darker blue for light mode
            }
        }
    }
    
    /// Default background color with dynamic light/dark mode support
    /// Implements Cross-platform UI Consistency requirement (Section 2.2.1)
    static var background: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "#121212", alpha: 1.0) // Dark background
            default:
                return UIColor(hex: "#FFFFFF", alpha: 1.0) // Light background
            }
        }
    }
    
    /// Default text color with dynamic light/dark mode support
    /// Implements Cross-platform UI Consistency requirement (Section 2.2.1)
    static var text: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "#FFFFFF", alpha: 1.0) // White text for dark mode
            default:
                return UIColor(hex: "#000000", alpha: 1.0) // Black text for light mode
            }
        }
    }
    
    /// Success state color with dynamic light/dark mode support
    /// Implements Cross-platform UI Consistency requirement (Section 2.2.1)
    static var success: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "#81C784", alpha: 1.0) // Light green for dark mode
            default:
                return UIColor(hex: "#388E3C", alpha: 1.0) // Dark green for light mode
            }
        }
    }
    
    /// Error state color with dynamic light/dark mode support
    /// Implements Cross-platform UI Consistency requirement (Section 2.2.1)
    static var error: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "#EF5350", alpha: 1.0) // Light red for dark mode
            default:
                return UIColor(hex: "#D32F2F", alpha: 1.0) // Dark red for light mode
            }
        }
    }
    
    /// Warning state color with dynamic light/dark mode support
    /// Implements Cross-platform UI Consistency requirement (Section 2.2.1)
    static var warning: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "#FFB74D", alpha: 1.0) // Light orange for dark mode
            default:
                return UIColor(hex: "#F57C00", alpha: 1.0) // Dark orange for light mode
            }
        }
    }
    
    // MARK: - Utility Functions
    
    /// Initializes a UIColor from a hex string with optional alpha value
    /// - Parameters:
    ///   - hex: The hex string representation of the color (e.g., "#FF0000" or "FF0000")
    ///   - alpha: The opacity value (0.0 - 1.0)
    /// Implements iOS Native Application requirement (Section 1.1)
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Converts the color to a hex string representation
    /// - Returns: A hex string representation of the color with # prefix
    /// Implements iOS Native Application requirement (Section 1.1)
    func toHex() -> String {
        guard let components = cgColor.components else { return "#000000" }
        
        let red = Int(components[0] * 255.0)
        let green = Int(components[1] * 255.0)
        let blue = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    /// Returns a new color with adjusted brightness
    /// - Parameter factor: The brightness adjustment factor (0.0 - 2.0, where 1.0 is unchanged)
    /// - Returns: A new UIColor instance with adjusted brightness
    /// Implements iOS Native Application requirement (Section 1.1)
    func adjustBrightness(factor: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }
        
        let newBrightness = max(0, min(brightness * factor, 1.0))
        return UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
    }
}