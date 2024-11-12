//
// CoreDataManager.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Configure encryption key storage in Keychain
// 2. Verify Core Data model version compatibility
// 3. Set up database migration strategy for schema updates
// 4. Configure iCloud container for sync capabilities
// 5. Review database performance metrics in production

// Core Data framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation

// Internal imports
import "../../../Common/Utils/Logger"

/// CoreDataManager provides centralized access to Core Data stack with thread-safe operations
/// Implements requirements from Section 4.3.2 Client Storage/iOS and 2.4 Security Architecture
final class CoreDataManager {
    
    // MARK: - Properties
    
    private let persistentContainer: NSPersistentContainer
    private let mainContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    private let serialQueue: DispatchQueue
    
    /// Encryption key identifier for store encryption
    private let encryptionKeyIdentifier = "com.mintreplicalite.coredata.encryption"
    
    // MARK: - Singleton
    
    /// Thread-safe singleton instance
    static let shared: CoreDataManager = {
        let instance = CoreDataManager()
        return instance
    }()
    
    // MARK: - Initialization
    
    private init() {
        // Initialize serial queue for thread-safe operations
        serialQueue = DispatchQueue(label: "com.mintreplicalite.coredata")
        
        // Initialize persistent container
        persistentContainer = NSPersistentContainer(name: "MintReplicaLite")
        
        // Configure store description with encryption
        // Implements requirement from Section 2.4 Security Architecture
        guard let storeDescription = persistentContainer.persistentStoreDescriptions.first else {
            fatalError("No persistent store description found")
        }
        
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreFileProtectionKey)
        storeDescription.shouldAddStoreAsynchronously = true
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        // Enable persistent history tracking for sync
        // Implements requirement from Section 1.2 Scope/Account Management
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        // Load persistent stores
        var loadError: Error?
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                loadError = error
                Logger.shared.log(
                    "Failed to load persistent store: \(error.localizedDescription)",
                    level: .critical,
                    category: .database
                )
            }
        }
        
        if let error = loadError {
            fatalError("Core Data store failed to load: \(error.localizedDescription)")
        }
        
        // Configure main context
        mainContext = persistentContainer.viewContext
        mainContext.automaticallyMergesChangesFromParent = true
        mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Configure background context
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        // Set up automatic merging of changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedObjectContextDidSave(_:)),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
        
        Logger.shared.log(
            "Core Data stack initialized successfully",
            level: .info,
            category: .database
        )
    }
    
    // MARK: - Context Management
    
    /// Saves changes in the specified context with proper error handling
    /// - Parameter context: The managed object context to save
    /// - Returns: Boolean indicating success
    @discardableResult
    func saveContext(_ context: NSManagedObjectContext) -> Bool {
        guard context.hasChanges else { return true }
        
        var success = false
        
        serialQueue.sync {
            do {
                try context.save()
                success = true
                Logger.shared.log(
                    "Context saved successfully",
                    level: .info,
                    category: .database
                )
            } catch {
                Logger.shared.log(
                    "Failed to save context: \(error.localizedDescription)",
                    level: .error,
                    category: .database
                )
            }
        }
        
        return success
    }
    
    /// Executes a block in a background context with proper error handling
    /// - Parameter block: The block to execute with the background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        
        context.performAndWait {
            block(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                    Logger.shared.log(
                        "Background task completed successfully",
                        level: .info,
                        category: .database
                    )
                } catch {
                    Logger.shared.log(
                        "Background task failed: \(error.localizedDescription)",
                        level: .error,
                        category: .database
                    )
                }
            }
        }
    }
    
    /// Securely removes all data from the Core Data store
    /// Implements requirement from Section 2.4 Security Architecture
    @discardableResult
    func clearDatabase() -> Bool {
        var success = false
        
        serialQueue.sync {
            guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
                Logger.shared.log(
                    "Failed to get store URL for database clearing",
                    level: .error,
                    category: .database
                )
                return
            }
            
            do {
                try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(
                    at: storeURL,
                    ofType: NSSQLiteStoreType,
                    options: nil
                )
                
                // Securely overwrite the file before deletion
                let fileHandle = try FileHandle(forWritingTo: storeURL)
                let bufferSize = 1024
                let zeros = Data(repeating: 0, count: bufferSize)
                let fileSize = try FileManager.default.attributesOfItem(atPath: storeURL.path)[.size] as! Int64
                
                for _ in stride(from: 0, to: fileSize, by: Int64(bufferSize)) {
                    fileHandle.write(zeros)
                }
                fileHandle.closeFile()
                
                try FileManager.default.removeItem(at: storeURL)
                
                // Recreate the store
                try persistentContainer.persistentStoreCoordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: storeURL,
                    options: [
                        NSPersistentStoreFileProtectionKey: FileProtectionType.complete
                    ]
                )
                
                success = true
                Logger.shared.log(
                    "Database cleared successfully",
                    level: .info,
                    category: .database
                )
            } catch {
                Logger.shared.log(
                    "Failed to clear database: \(error.localizedDescription)",
                    level: .error,
                    category: .database
                )
            }
        }
        
        return success
    }
    
    // MARK: - Private Methods
    
    @objc
    private func managedObjectContextDidSave(_ notification: Notification) {
        guard let sender = notification.object as? NSManagedObjectContext else { return }
        
        // Merge changes to main context if the save was performed on another context
        if sender !== mainContext {
            mainContext.perform {
                self.mainContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }
}