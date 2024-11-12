// HUMAN TASKS:
// 1. Verify Core Data model includes CategoryEntity with all required properties
// 2. Configure proper error handling and logging in the app delegate
// 3. Review and adjust API endpoint configuration for category synchronization

// Foundation framework - iOS 14.0+
import Foundation
// CoreData framework - iOS 14.0+
import CoreData
// Combine framework - iOS 14.0+
import Combine

// Import relative to current file location
import "../../../Domain/Models/Category"
import "../CoreData/Entities/CategoryEntity"
import "../CoreData/CoreDataManager"
import "../Network/APIClient"

/// Repository class managing category data persistence and synchronization with thread-safe operations
/// Requirements addressed:
/// - Category Management (1.2 Scope/Financial Tracking)
/// - Local Data Storage (4.3.2 Client Storage/iOS)
/// - Cross-platform Data Synchronization (1.2 Scope/Account Management)
@objc final class CategoryRepository {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the repository with Core Data context
    /// - Parameter context: Optional NSManagedObjectContext, defaults to main context
    init(context: NSManagedObjectContext? = nil) {
        self.context = context ?? CoreDataManager.shared.mainContext
        self.apiClient = .shared
    }
    
    // MARK: - Public Methods
    
    /// Fetches all categories from local storage with thread safety
    /// - Returns: Publisher emitting array of categories or error
    func fetchCategories() -> AnyPublisher<[Category], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "CategoryRepository",
                                      code: 1001,
                                      userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            CoreDataManager.shared.performBackgroundTask { context in
                do {
                    let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                    
                    let entities = try context.fetch(fetchRequest)
                    let categories = entities.map { $0.toDomain() }
                    promise(.success(categories))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Fetches a specific category by ID with thread safety
    /// - Parameter id: UUID of the category to fetch
    /// - Returns: Publisher emitting optional category or error
    func fetchCategory(id: UUID) -> AnyPublisher<Category?, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "CategoryRepository",
                                      code: 1001,
                                      userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            CoreDataManager.shared.performBackgroundTask { context in
                do {
                    let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    fetchRequest.fetchLimit = 1
                    
                    let entity = try context.fetch(fetchRequest).first
                    promise(.success(entity?.toDomain()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Saves category to local storage and syncs with server
    /// - Parameter category: Category to save
    /// - Returns: Publisher emitting saved category or error
    func saveCategory(_ category: Category) -> AnyPublisher<Category, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "CategoryRepository",
                                      code: 1001,
                                      userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            CoreDataManager.shared.performBackgroundTask { context in
                do {
                    // Create or update category entity
                    let entity = CategoryEntity.fromDomain(category, context: context)
                    
                    // Save local changes
                    try context.save()
                    
                    // Sync with server
                    self.apiClient.request(.saveCategory(category), responseType: Category.self)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { _ in
                                promise(.success(category))
                            }
                        )
                        .store(in: &self.cancellables)
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Deletes category from local storage and server
    /// - Parameter id: UUID of the category to delete
    /// - Returns: Publisher indicating completion or error
    func deleteCategory(id: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "CategoryRepository",
                                      code: 1001,
                                      userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            CoreDataManager.shared.performBackgroundTask { context in
                do {
                    let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    
                    let entities = try context.fetch(fetchRequest)
                    
                    // Delete local entity if found
                    if let entity = entities.first {
                        context.delete(entity)
                        try context.save()
                        
                        // Sync deletion with server
                        self.apiClient.request(.deleteCategory(id), responseType: Void.self)
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        promise(.failure(error))
                                    } else {
                                        promise(.success(()))
                                    }
                                },
                                receiveValue: { _ in }
                            )
                            .store(in: &self.cancellables)
                    } else {
                        promise(.success(()))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Synchronizes categories with the server
    /// - Returns: Publisher emitting synced categories or error
    func syncCategories() -> AnyPublisher<[Category], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "CategoryRepository",
                                      code: 1001,
                                      userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // Fetch latest categories from server
            self.apiClient.request(.getCategories, responseType: [Category].self)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { serverCategories in
                        CoreDataManager.shared.performBackgroundTask { context in
                            do {
                                // Fetch all local categories
                                let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
                                let localEntities = try context.fetch(fetchRequest)
                                
                                // Create dictionary of local categories by ID
                                let localById = Dictionary(uniqueKeysWithValues: localEntities.map { ($0.id, $0) })
                                
                                // Update or create categories from server
                                for category in serverCategories {
                                    if let existingEntity = localById[category.id] {
                                        existingEntity.update(from: category)
                                    } else {
                                        _ = CategoryEntity.fromDomain(category, context: context)
                                    }
                                }
                                
                                // Delete local categories that don't exist on server
                                let serverIds = Set(serverCategories.map { $0.id })
                                let localIds = Set(localById.keys)
                                let deletedIds = localIds.subtracting(serverIds)
                                
                                for id in deletedIds {
                                    if let entityToDelete = localById[id] {
                                        context.delete(entityToDelete)
                                    }
                                }
                                
                                // Save all changes
                                try context.save()
                                
                                promise(.success(serverCategories))
                            } catch {
                                promise(.failure(error))
                            }
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}