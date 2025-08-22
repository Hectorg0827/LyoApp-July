import CoreData
import Foundation

/// Production-ready Core Data stack for content caching
@MainActor
class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LyoModel")
        
        // Configure store description for better performance
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.shouldInferMappingModelAutomatically = true
        storeDescription?.shouldMigrateStoreAutomatically = true
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                print("❌ Core Data Error: \(error.localizedDescription)")
                // In production, you might want to handle this differently
                // For now, we'll continue with an in-memory store
                self?.fallbackToInMemoryStore(container: container)
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        // Configure context for automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        return container
    }()
    
    private func fallbackToInMemoryStore(container: NSPersistentContainer) {
        print("🔄 Falling back to in-memory Core Data store")
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Even in-memory store failed: \(error)")
            } else {
                print("✅ In-memory Core Data store ready")
            }
        }
    }
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }
    
    // MARK: - Save Context
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Core Data save error: \(error)")
        }
    }
    
    func saveBackground(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        context.performAndWait {
            do {
                try context.save()
            } catch {
                print("❌ Background context save error: \(error)")
            }
        }
    }
    
    // MARK: - Entity Operations
    
    /// Create or update a course from DTO
    func upsertCourse(from dto: CourseDTO, in context: NSManagedObjectContext? = nil) -> Course {
        let ctx = context ?? viewContext
        
        // Fetch existing course or create new one
        let course: Course
        if let existing = fetchCourse(by: dto.id, in: ctx) {
            course = existing
        } else {
            course = Course(context: ctx)
            course.id = dto.id
        }
        
        // Update properties
        course.title = dto.title
        course.topic = dto.topic
        course.summary = dto.summary
        course.status = dto.status
        course.createdAt = dto.createdAt
        course.ownerUserId = dto.ownerUserId
        course.progress = 0.0 // Will be updated separately
        
        return course
    }
    
    /// Create or update a lesson from DTO
    func upsertLesson(from dto: LessonDTO, courseId: String, in context: NSManagedObjectContext? = nil) -> Lesson {
        let ctx = context ?? viewContext
        
        // Fetch existing lesson or create new one
        let lesson: Lesson
        if let existing = fetchLesson(by: dto.id, in: ctx) {
            lesson = existing
        } else {
            lesson = Lesson(context: ctx)
            lesson.id = dto.id
        }
        
        // Update properties
        lesson.title = dto.title
        lesson.order = Int16(dto.order)
        lesson.summary = dto.summary
        lesson.courseId = courseId
        
        return lesson
    }
    
    /// Create or update a content item from DTO
    func upsertContentItem(from dto: ContentItemDTO, in context: NSManagedObjectContext? = nil) -> ContentItem? {
        let ctx = context ?? viewContext
        
        // Validate source URL
        guard URL(string: dto.sourceUrl) != nil else {
            print("⚠️ Dropping content item with invalid URL: \(dto.sourceUrl)")
            return nil
        }
        
        // Fetch existing item or create new one
        let item: ContentItem
        if let existing = fetchContentItem(by: dto.id, in: ctx) {
            item = existing
        } else {
            item = ContentItem(context: ctx)
            item.id = dto.id
        }
        
        // Update properties
        item.type = mapContentType(dto.type)
        item.title = dto.title
        item.source = dto.source
        item.sourceUrl = dto.sourceUrl
        item.thumbnailUrl = dto.thumbnailUrl
        item.durationSec = Int32(dto.durationSec ?? 0)
        item.pages = Int32(dto.pages ?? 0)
        item.summary = dto.summary
        item.attribution = dto.attribution
        item.courseId = dto.courseId
        item.lessonId = dto.lessonId
        
        // Store tags as JSON
        if let tags = dto.tags {
            item.tags = try? JSONSerialization.data(withJSONObject: tags, options: [])
        }
        
        return item
    }
    
    // MARK: - Fetch Operations
    
    func fetchCourse(by id: String, in context: NSManagedObjectContext? = nil) -> Course? {
        let ctx = context ?? viewContext
        let request: NSFetchRequest<Course> = Course.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        return try? ctx.fetch(request).first
    }
    
    func fetchLesson(by id: String, in context: NSManagedObjectContext? = nil) -> Lesson? {
        let ctx = context ?? viewContext
        let request: NSFetchRequest<Lesson> = Lesson.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        return try? ctx.fetch(request).first
    }
    
    func fetchContentItem(by id: String, in context: NSManagedObjectContext? = nil) -> ContentItem? {
        let ctx = context ?? viewContext
        let request: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        return try? ctx.fetch(request).first
    }
    
    func fetchCourses(limit: Int = 20) -> [Course] {
        let request: NSFetchRequest<Course> = Course.fetchRequest()
        request.fetchLimit = limit
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Course.createdAt, ascending: false)]
        
        return (try? viewContext.fetch(request)) ?? []
    }
    
    // MARK: - Helper Methods
    
    private func mapContentType(_ type: String) -> String {
        // Map unknown types to "article" as specified
        let knownTypes = ["video", "article", "pdf", "book", "podcast"]
        return knownTypes.contains(type.lowercased()) ? type.lowercased() : "article"
    }
}