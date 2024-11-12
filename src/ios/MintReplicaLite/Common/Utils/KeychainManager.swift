//
// KeychainManager.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify keychain access group configuration in Xcode entitlements
// 2. Configure keychain sharing if needed for app extensions
// 3. Review biometric authentication settings with security team
// 4. Ensure proper error logging configuration in production

import Foundation // version: iOS 14.0+
import Security // version: iOS 14.0+
import LocalAuthentication // version: iOS 14.0+ (for biometric authentication)
import CommonCrypto // version: iOS 14.0+ (for AES encryption)

// Relative imports
import Common.Constants.ErrorConstants
import Common.Utils.Logger

/// Custom error types for keychain operations
/// Requirement: Error Handling - Generic error messages and proper error handling
enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unhandledError(status: OSStatus)
    case encodingError
    case decodingError
}

/// Thread-safe singleton class managing secure storage and retrieval of sensitive data
/// Requirement: Secure Storage - Platform-specific secure storage implementation
@objc final class KeychainManager {
    
    // MARK: - Properties
    
    private let serviceName: String
    private let accessGroup: String?
    
    /// Shared singleton instance
    static let shared = KeychainManager()
    
    // Encryption configuration
    private let encryptionKey: Data
    private let aesKeySize = kCCKeySizeAES256
    private let aesBlockSize = kCCBlockSizeAES128
    
    // MARK: - Initialization
    
    private init() {
        // Initialize service name from bundle identifier
        self.serviceName = Bundle.main.bundleIdentifier ?? "com.mintreplicaLite"
        
        // Set up access group for keychain sharing if needed
        #if DEBUG
        self.accessGroup = nil
        #else
        self.accessGroup = "com.mintreplicaLite.shared"
        #endif
        
        // Generate or retrieve encryption key
        if let existingKey = try? retrieveEncryptionKey() {
            self.encryptionKey = existingKey
        } else {
            self.encryptionKey = generateEncryptionKey()
            try? saveEncryptionKey(self.encryptionKey)
        }
        
        // Initialize secure logging
        Logger.shared.log(
            "KeychainManager initialized",
            level: .debug,
            category: .security
        )
    }
    
    // MARK: - Public Methods
    
    /// Saves data securely to keychain with AES-256 encryption
    /// Requirement: Sensitive Data Protection - Financial credentials stored with AES-256 encryption
    func save(data: Data, key: String, useBiometrics: Bool = false) -> Result<Void, KeychainError> {
        do {
            // Encrypt data using AES-256
            let encryptedData = try encrypt(data: data)
            
            // Prepare query dictionary
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: key,
                kSecValueData as String: encryptedData,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            // Add access group if specified
            if let accessGroup = accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
            
            // Add biometric protection if requested
            if useBiometrics {
                let context = LAContext()
                var error: NSError?
                
                guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                    Logger.shared.log(
                        "Biometric authentication not available: \(error?.localizedDescription ?? "")",
                        level: .error,
                        category: .security
                    )
                    return .failure(.invalidData)
                }
                
                let accessControl = SecAccessControlCreateWithFlags(
                    nil,
                    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                    .biometryAny,
                    nil
                )
                query[kSecAttrAccessControl as String] = accessControl
            }
            
            // Attempt to save to keychain
            let status = SecItemAdd(query as CFDictionary, nil)
            
            switch status {
            case errSecSuccess:
                Logger.shared.log(
                    "Successfully saved item to keychain: \(key)",
                    level: .debug,
                    category: .security
                )
                return .success(())
                
            case errSecDuplicateItem:
                // Item exists, update it
                let updateQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: serviceName,
                    kSecAttrAccount as String: key
                ]
                
                let updateAttributes: [String: Any] = [
                    kSecValueData as String: encryptedData
                ]
                
                let updateStatus = SecItemUpdate(
                    updateQuery as CFDictionary,
                    updateAttributes as CFDictionary
                )
                
                guard updateStatus == errSecSuccess else {
                    Logger.shared.log(
                        "Failed to update keychain item: \(updateStatus)",
                        level: .error,
                        category: .security
                    )
                    return .failure(.unhandledError(status: updateStatus))
                }
                
                Logger.shared.log(
                    "Successfully updated keychain item: \(key)",
                    level: .debug,
                    category: .security
                )
                return .success(())
                
            default:
                Logger.shared.log(
                    "Failed to save to keychain: \(status)",
                    level: .error,
                    category: .security
                )
                return .failure(.unhandledError(status: status))
            }
        } catch {
            Logger.shared.log(
                "Encryption error while saving to keychain: \(error)",
                level: .error,
                category: .security
            )
            return .failure(.encodingError)
        }
    }
    
    /// Retrieves and decrypts data from keychain
    /// Requirement: Platform Security - iOS Keychain Services implementation
    func retrieve(key: String) -> Result<Data, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let encryptedData = result as? Data else {
            Logger.shared.log(
                "Failed to retrieve from keychain: \(status)",
                level: .error,
                category: .security
            )
            return .failure(status == errSecItemNotFound ? .itemNotFound : .unhandledError(status: status))
        }
        
        do {
            let decryptedData = try decrypt(data: encryptedData)
            Logger.shared.log(
                "Successfully retrieved item from keychain: \(key)",
                level: .debug,
                category: .security
            )
            return .success(decryptedData)
        } catch {
            Logger.shared.log(
                "Decryption error while retrieving from keychain: \(error)",
                level: .error,
                category: .security
            )
            return .failure(.decodingError)
        }
    }
    
    /// Securely deletes data from keychain
    /// Requirement: Secure Storage - Platform-specific secure storage implementation
    func delete(key: String) -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            Logger.shared.log(
                "Failed to delete from keychain: \(status)",
                level: .error,
                category: .security
            )
            return .failure(.unhandledError(status: status))
        }
        
        Logger.shared.log(
            "Successfully deleted item from keychain: \(key)",
            level: .debug,
            category: .security
        )
        return .success(())
    }
    
    /// Removes all keychain items for the app
    /// Requirement: Secure Storage - Platform-specific secure storage implementation
    func clear() -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            Logger.shared.log(
                "Failed to clear keychain: \(status)",
                level: .error,
                category: .security
            )
            return .failure(.unhandledError(status: status))
        }
        
        Logger.shared.log(
            "Successfully cleared all keychain items",
            level: .debug,
            category: .security
        )
        return .success(())
    }
    
    // MARK: - Private Methods
    
    private func generateEncryptionKey() -> Data {
        var keyData = Data(count: aesKeySize)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, aesKeySize, $0.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            fatalError("Failed to generate encryption key")
        }
        
        return keyData
    }
    
    private func saveEncryptionKey(_ key: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "com.mintreplicaLite.encryptionKey",
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    private func retrieveEncryptionKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "com.mintreplicaLite.encryptionKey",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw KeychainError.unhandledError(status: status)
        }
        
        return keyData
    }
    
    private func encrypt(data: Data) throws -> Data {
        let bufferSize = data.count + aesBlockSize
        var buffer = Data(count: bufferSize)
        
        var numBytesEncrypted: size_t = 0
        
        let status = buffer.withUnsafeMutableBytes { bufferPtr in
            data.withUnsafeBytes { dataPtr in
                encryptionKey.withUnsafeBytes { keyPtr in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyPtr.baseAddress,
                        aesKeySize,
                        nil,
                        dataPtr.baseAddress,
                        data.count,
                        bufferPtr.baseAddress,
                        bufferSize,
                        &numBytesEncrypted
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw KeychainError.encodingError
        }
        
        return buffer.prefix(numBytesEncrypted)
    }
    
    private func decrypt(data: Data) throws -> Data {
        let bufferSize = data.count + aesBlockSize
        var buffer = Data(count: bufferSize)
        
        var numBytesDecrypted: size_t = 0
        
        let status = buffer.withUnsafeMutableBytes { bufferPtr in
            data.withUnsafeBytes { dataPtr in
                encryptionKey.withUnsafeBytes { keyPtr in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyPtr.baseAddress,
                        aesKeySize,
                        nil,
                        dataPtr.baseAddress,
                        data.count,
                        bufferPtr.baseAddress,
                        bufferSize,
                        &numBytesDecrypted
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw KeychainError.decodingError
        }
        
        return buffer.prefix(numBytesDecrypted)
    }
}