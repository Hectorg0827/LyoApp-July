import CoreData
import Foundation

// MARK: - Core Data Manager
/// Central Core Data management system for LyoApp
class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LyoAppDataModel")
        
        // Configure store description
        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Handle Core Data error gracefully
                print("Core Data error: \(error), \(error.userInfo)")
                // In production, you might want to delete the store and recreate it
                // or show a user-friendly error message
            }
        }
        
        // Configure merge policy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // MARK: - Core Data Context
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Background Context
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Save Context
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
                // Handle save error appropriately
            }
        }
    }
    
    // MARK: - Background Save
    func saveInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let backgroundContext = self.backgroundContext
        backgroundContext.perform {
            block(backgroundContext)
            
            if backgroundContext.hasChanges {
                do {
                    try backgroundContext.save()
                } catch {
                    print("Failed to save background context: \(error)")
                }
            }
        }
    }
    
    // MARK: - Batch Delete
    func batchDelete(for entityName: String) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
    }
    
    // MARK: - Reset Store
    func resetStore() {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            return
        }
        
        do {
            try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(
                at: storeURL,
                ofType: NSSQLiteStoreType,
                options: nil
            )
            
            // Recreate the store
            try persistentContainer.persistentStoreCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: nil
            )
        } catch {
            print("Failed to reset Core Data store: \(error)")
        }
    }
}
