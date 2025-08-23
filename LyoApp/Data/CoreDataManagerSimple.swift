import CoreData
import Foundation

/// Simplified Core Data manager for production app
class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LyoApp")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data failed to load store: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Failed to save context: \(error)")
            }
        }
    }
    
    // MARK: - Basic User Methods
    func createUser(
        id: String,
        username: String,
        displayName: String?,
        email: String?,
        isVerified: Bool = false
    ) -> CoreDataUserEntity {
        let user = CoreDataUserEntity(context: context)
        user.id = id
        user.username = username
        user.displayName = displayName
        user.email = email
        user.isVerified = isVerified
        user.followerCount = 0
        user.followingCount = 0
        user.postCount = 0
        user.createdAt = Date()
        user.updatedAt = Date()
        
        save()
        return user
    }
    
    func fetchUser(by id: String) -> CoreDataUserEntity? {
        let request: NSFetchRequest<CoreDataUserEntity> = NSFetchRequest<CoreDataUserEntity>(entityName: "CoreDataUserEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to fetch user: \(error)")
            return nil
        }
    }
    
    func fetchAllUsers() -> [CoreDataUserEntity] {
        let request: NSFetchRequest<CoreDataUserEntity> = NSFetchRequest<CoreDataUserEntity>(entityName: "CoreDataUserEntity")
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch users: \(error)")
            return []
        }
    }
}

// MARK: - User Conversion Extension
extension User {
    func toCoreDataEntity(context: NSManagedObjectContext) -> CoreDataUserEntity {
        let entity = CoreDataUserEntity(context: context)
        entity.id = self.id
        entity.username = self.username
        entity.displayName = self.displayName
        entity.email = self.email
        entity.isVerified = self.isVerified
        entity.followerCount = Int32(self.followerCount)
        entity.followingCount = Int32(self.followingCount)
        entity.postCount = Int32(self.postCount)
        entity.avatarURL = self.avatarURL
        entity.createdAt = self.createdAt
        entity.updatedAt = self.updatedAt
        return entity
    }
}
