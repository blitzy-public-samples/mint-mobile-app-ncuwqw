//
// User.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Review biometric authentication configuration with security team
// 2. Verify email verification flow requirements with backend team
// 3. Confirm user preference keys with product team
// 4. Ensure GDPR compliance for user data handling

// Foundation framework - iOS 14.0+
import Foundation

// Relative imports
import "../Common/Constants/APIConstants"
import "../Common/Extensions/String+Extensions"

/// Defines the access level and permissions for a user
/// Implements Account Management requirement from Section 1.2 Scope
@objc public enum UserRole: String {
    case standard
    case premium
    case admin
}

/// Represents the current state of a user account
/// Implements Account Management requirement from Section 1.2 Scope
@objc public enum UserStatus: String {
    case active
    case inactive
    case suspended
    case pendingVerification
}

/// Main user model class representing a user in the system with secure data handling
/// Implements Account Management requirement from Section 1.2 Scope and
/// Data Security requirement from Section 2.4 Security Architecture
@objc @objcMembers public class User: NSObject, Codable, Equatable {
    
    // MARK: - Properties
    
    public let id: UUID
    public var email: String
    public var firstName: String
    public var lastName: String
    public var role: UserRole
    public var status: UserStatus
    public let createdAt: Date
    public var lastLoginAt: Date
    public var isEmailVerified: Bool
    public var hasBiometricEnabled: Bool
    public var preferences: [String: Any]
    
    private enum CodingKeys: String, CodingKey {
        case id, email, firstName, lastName, role, status
        case createdAt, lastLoginAt, isEmailVerified
        case hasBiometricEnabled, preferences
    }
    
    // MARK: - Initialization
    
    /// Initializes a new User instance with validation
    /// Implements Data Security requirement from Section 2.4
    public init(id: UUID, email: String, firstName: String, lastName: String) throws {
        guard email.isValidEmail() else {
            throw NSError(domain: "UserValidation",
                         code: 1001,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid email format"])
        }
        
        self.id = id
        self.email = email
        self.firstName = firstName.trimmedAndValidated()
        self.lastName = lastName.trimmedAndValidated()
        self.role = .standard
        self.status = .pendingVerification
        self.createdAt = Date()
        self.lastLoginAt = Date()
        self.isEmailVerified = false
        self.hasBiometricEnabled = false
        self.preferences = [:]
        
        super.init()
    }
    
    // MARK: - Codable Implementation
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        role = try container.decode(UserRole.self, forKey: .role)
        status = try container.decode(UserStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastLoginAt = try container.decode(Date.self, forKey: .lastLoginAt)
        isEmailVerified = try container.decode(Bool.self, forKey: .isEmailVerified)
        hasBiometricEnabled = try container.decode(Bool.self, forKey: .hasBiometricEnabled)
        
        // Decode preferences dictionary
        if let preferencesData = try container.decodeIfPresent(Data.self, forKey: .preferences),
           let decodedPreferences = try? JSONSerialization.jsonObject(with: preferencesData) as? [String: Any] {
            preferences = decodedPreferences
        } else {
            preferences = [:]
        }
        
        super.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(role, forKey: .role)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastLoginAt, forKey: .lastLoginAt)
        try container.encode(isEmailVerified, forKey: .isEmailVerified)
        try container.encode(hasBiometricEnabled, forKey: .hasBiometricEnabled)
        
        // Encode preferences dictionary
        if let preferencesData = try? JSONSerialization.data(withJSONObject: preferences) {
            try container.encode(preferencesData, forKey: .preferences)
        }
    }
    
    // MARK: - Public Methods
    
    /// Returns the user's full name with proper formatting
    /// Implements Account Management requirement from Section 1.2
    public func fullName() -> String {
        let trimmedFirstName = firstName.trimmedAndValidated()
        let trimmedLastName = lastName.trimmedAndValidated()
        return "\(trimmedFirstName) \(trimmedLastName)".trimmedAndValidated()
    }
    
    /// Updates a user preference setting with validation
    /// Implements Data Security requirement from Section 2.4
    public func updatePreference(key: String, value: Any) {
        guard !key.trimmedAndValidated().isEmpty else { return }
        
        preferences[key] = value
        
        // Post notification for preference update
        NotificationCenter.default.post(
            name: NSNotification.Name("UserPreferenceChanged"),
            object: self,
            userInfo: ["key": key, "value": value]
        )
    }
    
    /// Validates the user's email format using secure validation
    /// Implements Data Security requirement from Section 2.4
    public func validateEmail() -> Bool {
        return email.isValidEmail()
    }
    
    // MARK: - Equatable Implementation
    
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.email == rhs.email &&
               lhs.firstName == rhs.firstName &&
               lhs.lastName == rhs.lastName &&
               lhs.role == rhs.role &&
               lhs.status == rhs.status &&
               lhs.isEmailVerified == rhs.isEmailVerified &&
               lhs.hasBiometricEnabled == rhs.hasBiometricEnabled
    }
}