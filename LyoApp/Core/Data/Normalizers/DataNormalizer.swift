import Foundation
import CoreData

/// Data normalizer for transforming API responses into Core Data entities
class DataNormalizer {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Course Normalization
    
    /// Normalize a course DTO and its related data in a single transaction
    @MainActor
    func normalizeCourse(_ dto: CourseDTO) throws {
        let backgroundContext = coreDataStack.newBackgroundContext()
        
        try backgroundContext.performAndWait {
            // Upsert the course
            let course = coreDataStack.upsertCourse(from: dto, in: backgroundContext)
            
            // Normalize lessons
            for lessonDTO in dto.lessons {
                let lesson = coreDataStack.upsertLesson(from: lessonDTO, courseId: dto.id, in: backgroundContext)
                lesson.course = course
            }
            
            // Normalize content items
            var validItemsCount = 0
            for itemDTO in dto.items {
                if let item = coreDataStack.upsertContentItem(from: itemDTO, in: backgroundContext) {
                    item.course = course
                    
                    // Associate with lesson if specified
                    if let lessonId = itemDTO.lessonId {
                        if let lesson = coreDataStack.fetchLesson(by: lessonId, in: backgroundContext) {
                            item.lesson = lesson
                        }
                    }
                    
                    validItemsCount += 1
                }
            }
            
            // Save all changes in one transaction
            coreDataStack.saveBackground(backgroundContext)
            
            print("✅ Normalized course '\(dto.title)' with \(dto.lessons.count) lessons and \(validItemsCount)/\(dto.items.count) content items")
        }
    }
    
    // MARK: - Batch Normalization
    
    /// Normalize multiple courses in a single transaction
    @MainActor
    func normalizeCourses(_ dtos: [CourseDTO]) throws {
        let backgroundContext = coreDataStack.newBackgroundContext()
        
        try backgroundContext.performAndWait {
            var totalLessons = 0
            var totalValidItems = 0
            var totalItems = 0
            
            for dto in dtos {
                // Upsert the course
                let course = coreDataStack.upsertCourse(from: dto, in: backgroundContext)
                
                // Normalize lessons
                for lessonDTO in dto.lessons {
                    let lesson = coreDataStack.upsertLesson(from: lessonDTO, courseId: dto.id, in: backgroundContext)
                    lesson.course = course
                    totalLessons += 1
                }
                
                // Normalize content items
                for itemDTO in dto.items {
                    totalItems += 1
                    if let item = coreDataStack.upsertContentItem(from: itemDTO, in: backgroundContext) {
                        item.course = course
                        
                        // Associate with lesson if specified
                        if let lessonId = itemDTO.lessonId {
                            if let lesson = coreDataStack.fetchLesson(by: lessonId, in: backgroundContext) {
                                item.lesson = lesson
                            }
                        }
                        
                        totalValidItems += 1
                    }
                }
            }
            
            // Save all changes in one transaction
            coreDataStack.saveBackground(backgroundContext)
            
            print("✅ Normalized \(dtos.count) courses with \(totalLessons) lessons and \(totalValidItems)/\(totalItems) content items")
        }
    }
    
    // MARK: - User Normalization
    
    /// Normalize user data
    @MainActor 
    func normalizeUser(_ dto: UserDTO) throws {
        let backgroundContext = coreDataStack.newBackgroundContext()
        
        try backgroundContext.performAndWait {
            // Fetch existing user or create new one
            let user: User
            if let existing = fetchUser(by: dto.id, in: backgroundContext) {
                user = existing
            } else {
                user = User(context: backgroundContext)
                user.id = dto.id
            }
            
            // Update properties
            user.name = dto.name
            user.avatarUrl = dto.avatarUrl
            user.xp = Int32(dto.xp)
            user.streak = Int32(dto.streak)
            
            coreDataStack.saveBackground(backgroundContext)
            
            print("✅ Normalized user '\(dto.name)'")
        }
    }
    
    // MARK: - Feed Data Normalization
    
    /// Normalize feed response with cursor pagination
    @MainActor
    func normalizeFeedResponse(_ response: FeedResponse) throws -> String? {
        // For now, we'll focus on course-related feed items
        // In a full implementation, you might want separate entities for feed items
        
        let courseDTOs = response.items.compactMap { $0.course }
        if !courseDTOs.isEmpty {
            try normalizeCourses(courseDTOs)
        }
        
        // Normalize any users mentioned in feed items
        let userDTOs = response.items.compactMap { $0.author }
        for userDTO in userDTOs {
            try normalizeUser(userDTO)
        }
        
        print("✅ Normalized feed with \(response.items.count) items")
        return response.nextCursor
    }
    
    // MARK: - Validation and Error Handling
    
    /// Validate content item data before normalization
    private func validateContentItem(_ dto: ContentItemDTO) -> Bool {
        // Check for required fields
        guard !dto.id.isEmpty,
              !dto.title.isEmpty,
              !dto.sourceUrl.isEmpty else {
            print("⚠️ Content item missing required fields: \(dto.id)")
            return false
        }
        
        // Validate URL format
        guard URL(string: dto.sourceUrl) != nil else {
            print("⚠️ Content item has invalid URL: \(dto.sourceUrl)")
            return false
        }
        
        // Check for reasonable duration for videos
        if dto.type.lowercased() == "video" {
            if let duration = dto.durationSec, duration > 86400 { // > 24 hours
                print("⚠️ Video content has unrealistic duration: \(duration) seconds")
                return false
            }
        }
        
        // Check for reasonable page count for books/PDFs
        if ["book", "pdf"].contains(dto.type.lowercased()) {
            if let pages = dto.pages, pages > 10000 {
                print("⚠️ Document has unrealistic page count: \(pages)")
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    
    private func fetchUser(by id: String, in context: NSManagedObjectContext) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    /// Clean up old or orphaned data
    @MainActor
    func performCleanup() throws {
        let backgroundContext = coreDataStack.newBackgroundContext()
        
        try backgroundContext.performAndWait {
            // Remove content items with invalid URLs
            let invalidItemsRequest: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
            invalidItemsRequest.predicate = NSPredicate(format: "sourceUrl == NULL OR sourceUrl == ''")
            
            let invalidItems = try backgroundContext.fetch(invalidItemsRequest)
            for item in invalidItems {
                backgroundContext.delete(item)
            }
            
            // Remove orphaned lessons (lessons without a course)
            let orphanedLessonsRequest: NSFetchRequest<Lesson> = Lesson.fetchRequest()
            orphanedLessonsRequest.predicate = NSPredicate(format: "course == NULL")
            
            let orphanedLessons = try backgroundContext.fetch(orphanedLessonsRequest)
            for lesson in orphanedLessons {
                backgroundContext.delete(lesson)
            }
            
            coreDataStack.saveBackground(backgroundContext)
            
            if invalidItems.count > 0 || orphanedLessons.count > 0 {
                print("🧹 Cleaned up \(invalidItems.count) invalid items and \(orphanedLessons.count) orphaned lessons")
            }
        }
    }
}