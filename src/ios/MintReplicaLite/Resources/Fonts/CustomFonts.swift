//
// CustomFonts.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify SF Pro font files are included in the app bundle
// 2. Add font files to Info.plist under "Fonts provided by application"
// 3. Validate font metrics against iOS Human Interface Guidelines
// 4. Test font scaling with different accessibility settings

import UIKit

// Relative import from Common/Constants
import ../../Common/Constants/AppConstants

// Font family enumeration
private enum FontFamily: String {
    case sfPro = "SFPro"
}

// Font weight enumeration
private enum FontWeight: String {
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "Semibold"
    case bold = "Bold"
}

// Custom font registration error types
enum CustomFontError: Error {
    case fileNotFound
    case registrationFailed
}

/// Registers custom fonts with the system
/// Implements iOS Native Implementation requirement from Section 1.1
/// - Returns: Result indicating success or failure of font registration
func registerCustomFonts() -> Result<Bool, CustomFontError> {
    guard let bundle = Bundle.main else {
        return .failure(.fileNotFound)
    }
    
    let fontExtensions = ["otf", "ttf"]
    var isSuccess = true
    
    for ext in fontExtensions {
        if let fontURLs = bundle.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") {
            for url in fontURLs {
                var errorRef: Unmanaged<CFError>?
                if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef) {
                    isSuccess = false
                    print("Error registering font: \(url.lastPathComponent)")
                }
            }
        }
    }
    
    return isSuccess ? .success(true) : .failure(.registrationFailed)
}

/// Calculates scaled font size based on user's accessibility settings
/// Implements Platform-Specific UI requirement from Section 5.1.7
/// - Parameter baseSize: Base font size to scale
/// - Returns: Scaled font size according to accessibility preferences
func scaledFontSize(_ baseSize: CGFloat) -> CGFloat {
    let contentSize = UIApplication.shared.preferredContentSizeCategory
    
    let scaleFactor: CGFloat
    switch contentSize {
    case .extraSmall:
        scaleFactor = 0.8
    case .small:
        scaleFactor = 0.9
    case .medium:
        scaleFactor = 1.0
    case .large:
        scaleFactor = 1.1
    case .extraLarge:
        scaleFactor = 1.2
    case .extraExtraLarge:
        scaleFactor = 1.3
    case .extraExtraExtraLarge:
        scaleFactor = 1.4
    case .accessibilityMedium:
        scaleFactor = 1.6
    case .accessibilityLarge:
        scaleFactor = 1.8
    case .accessibilityExtraLarge:
        scaleFactor = 2.0
    case .accessibilityExtraExtraLarge:
        scaleFactor = 2.2
    case .accessibilityExtraExtraExtraLarge:
        scaleFactor = 2.4
    default:
        scaleFactor = 1.0
    }
    
    return baseSize * scaleFactor
}

/// Custom fonts enumeration with iOS HIG-compliant metrics
/// Implements Platform-Specific UI requirement from Section 5.1.7
enum CustomFonts {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case subheadline
    case body
    case callout
    case footnote
    case caption1
    case caption2
    
    /// Font name for the current text style
    var fontName: String {
        let family = FontFamily.sfPro.rawValue
        let weight: String
        
        switch self {
        case .largeTitle, .title1:
            weight = FontWeight.bold.rawValue
        case .title2, .title3, .headline:
            weight = FontWeight.semibold.rawValue
        case .subheadline, .callout:
            weight = FontWeight.medium.rawValue
        case .body, .footnote, .caption1, .caption2:
            weight = FontWeight.regular.rawValue
        }
        
        return "\(family)-\(weight)"
    }
    
    /// Default size following iOS Human Interface Guidelines
    var defaultSize: CGFloat {
        switch self {
        case .largeTitle: return 34.0
        case .title1: return 28.0
        case .title2: return 22.0
        case .title3: return 20.0
        case .headline: return 17.0
        case .subheadline: return 15.0
        case .body: return 17.0
        case .callout: return 16.0
        case .footnote: return 13.0
        case .caption1: return 12.0
        case .caption2: return 11.0
        }
    }
    
    /// Font weight for the current text style
    var weight: FontWeight {
        switch self {
        case .largeTitle, .title1:
            return .bold
        case .title2, .title3, .headline:
            return .semibold
        case .subheadline, .callout:
            return .medium
        case .body, .footnote, .caption1, .caption2:
            return .regular
        }
    }
    
    /// Line height multiplier for proper vertical rhythm
    var lineHeight: CGFloat {
        switch self {
        case .largeTitle: return 1.3
        case .title1: return 1.3
        case .title2: return 1.3
        case .title3: return 1.25
        case .headline: return 1.2
        case .subheadline: return 1.2
        case .body: return 1.25
        case .callout: return 1.2
        case .footnote: return 1.15
        case .caption1: return 1.15
        case .caption2: return 1.15
        }
    }
    
    /// Returns UIFont instance with proper scaling for accessibility
    /// - Parameter size: Optional custom size, defaults to standard size if nil
    /// - Returns: Configured UIFont instance
    func font(size customSize: CGFloat? = nil) -> UIFont {
        let size = customSize ?? defaultSize
        let scaledSize = scaledFontSize(size)
        
        if let font = UIFont(name: fontName, size: scaledSize) {
            let metrics = UIFontMetrics(forTextStyle: textStyle)
            return metrics.scaledFont(for: font)
        }
        
        // Fallback to system font if custom font is not available
        return UIFont.systemFont(ofSize: scaledSize, weight: systemWeight)
    }
    
    /// Returns dynamically scaled UIFont for accessibility
    /// - Returns: Scaled font instance
    func scaledFont() -> UIFont {
        return font()
    }
    
    // MARK: - Private Helpers
    
    private var textStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title1: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption1: return .caption1
        case .caption2: return .caption2
        }
    }
    
    private var systemWeight: UIFont.Weight {
        switch weight {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}