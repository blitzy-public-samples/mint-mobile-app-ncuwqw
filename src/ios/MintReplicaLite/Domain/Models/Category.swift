// HUMAN TASKS:
// None required - this is a self-contained domain model

// Foundation framework - iOS 14.0+
import Foundation

/// Defines the types of transaction categories for proper classification and analysis
/// Requirement: Transaction Categorization (1.2 Scope/Financial Tracking)
@objc public enum CategoryType: String, Codable {
    case income
    case expense
    case transfer
}

/// Represents a transaction category in the system with support for hierarchical organization
/// Requirements addressed:
/// - Category Management (1.2 Scope/Financial Tracking)
/// - Budget Management (1.2 Scope/Budget Management)
/// - Transaction Categorization (1.2 Scope/Financial Tracking)
@objc public final class Category: NSObject, Codable {
    // MARK: - Properties
    
    /// Unique identifier for the category
    public let id: UUID
    
    /// Name of the category
    public private(set) var name: String
    
    /// Type of the category (income, expense, or transfer)
    public private(set) var type: CategoryType
    
    /// Optional parent category identifier for hierarchical organization
    public private(set) var parentId: UUID?
    
    /// Flag indicating if this is a system-defined category
    public private(set) var isSystem: Bool
    
    /// Timestamp when the category was created
    public let createdAt: Date
    
    /// Timestamp when the category was last updated
    public private(set) var updatedAt: Date
    
    // MARK: - Initialization
    
    /// Initializes a new Category instance with required properties and default values
    /// - Parameters:
    ///   - id: Unique identifier for the category
    ///   - name: Name of the category
    ///   - type: Type of the category
    public init(id: UUID, name: String, type: CategoryType) throws {
        // Validate that name is not empty
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "CategoryError",
                         code: 1001,
                         userInfo: [NSLocalizedDescriptionKey: "Category name cannot be empty"])
        }
        
        self.id = id
        self.name = name
        self.type = type
        self.parentId = nil
        self.isSystem = false
        self.createdAt = Date()
        self.updatedAt = Date()
        
        super.init()
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case parentId
        case isSystem
        case createdAt
        case updatedAt
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(CategoryType.self, forKey: .type)
        parentId = try container.decodeIfPresent(UUID.self, forKey: .parentId)
        isSystem = try container.decode(Bool.self, forKey: .isSystem)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        super.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encode(isSystem, forKey: .isSystem)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Public Methods
    
    /// Updates mutable category properties while maintaining data integrity
    /// - Parameters:
    ///   - name: Optional new name for the category
    ///   - type: Optional new type for the category
    ///   - parentId: Optional new parent category identifier
    public func update(name: String? = nil, type: CategoryType? = nil, parentId: UUID? = nil) throws {
        // Update name if provided and not empty
        if let newName = name {
            guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NSError(domain: "CategoryError",
                            code: 1001,
                            userInfo: [NSLocalizedDescriptionKey: "Category name cannot be empty"])
            }
            self.name = newName
        }
        
        // Update type if provided
        if let newType = type {
            self.type = newType
        }
        
        // Update parentId if provided
        if let newParentId = parentId {
            self.parentId = newParentId
        }
        
        // Update the updatedAt timestamp
        self.updatedAt = Date()
    }
    
    /// Determines if the category is a parent category in the hierarchy
    /// - Returns: True if category has no parent, false otherwise
    public func isParentCategory() -> Bool {
        return parentId == nil
    }
    
    // MARK: - NSObject Overrides
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Category else { return false }
        return self.id == other.id
    }
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }
    
    public override var description: String {
        return "Category(id: \(id), name: \(name), type: \(type), parentId: \(String(describing: parentId)), isSystem: \(isSystem))"
    }
}