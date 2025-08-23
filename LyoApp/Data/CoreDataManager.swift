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
        fullName: String?,
        email: String?
    ) -> CoreDataUserEntity {
        let user = CoreDataUserEntity(context: context)
        user.id = id
        user.username = username
        user.fullName = fullName ?? username
        user.email = email ?? ""
        user.followers = 0
        user.following = 0
        user.posts = 0
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
    
    // MARK: - Course Operations
    func fetchCourses() -> [CourseEntity] {
        let request: NSFetchRequest<CourseEntity> = NSFetchRequest<CourseEntity>(entityName: "CourseEntity")
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch courses: \(error)")
            return []
        }
    }
}
