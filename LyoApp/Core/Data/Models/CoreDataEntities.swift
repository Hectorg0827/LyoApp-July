import CoreData
import Foundation

// MARK: - Course Entity
@objc(Course)
public class Course: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var topic: String
    @NSManaged public var summary: String?
    @NSManaged public var status: String
    @NSManaged public var createdAt: Date
    @NSManaged public var ownerUserId: String
    @NSManaged public var progress: Double
    
    // Relationships
    @NSManaged public var lessons: Set<Lesson>?
    @NSManaged public var contentItems: Set<ContentItem>?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Course> {
        return NSFetchRequest<Course>(entityName: "Course")
    }
    
    /// Get lessons in order
    public var orderedLessons: [Lesson] {
        return lessons?.sorted { $0.order < $1.order } ?? []
    }
    
    /// Get content items for this course
    public var courseContentItems: [ContentItem] {
        return contentItems?.filter { $0.courseId == self.id } ?? []
    }
}

// MARK: - Lesson Entity
@objc(Lesson)
public class Lesson: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var courseId: String
    @NSManaged public var title: String
    @NSManaged public var order: Int16
    @NSManaged public var summary: String?
    
    // Relationships
    @NSManaged public var course: Course?
    @NSManaged public var contentItems: Set<ContentItem>?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Lesson> {
        return NSFetchRequest<Lesson>(entityName: "Lesson")
    }
    
    /// Get content items for this lesson
    public var lessonContentItems: [ContentItem] {
        return contentItems?.filter { $0.lessonId == self.id } ?? []
    }
}

// MARK: - Content Item Entity
@objc(ContentItem) 
public class ContentItem: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var courseId: String?
    @NSManaged public var lessonId: String?
    @NSManaged public var type: String
    @NSManaged public var title: String
    @NSManaged public var source: String
    @NSManaged public var sourceUrl: String
    @NSManaged public var thumbnailUrl: String?
    @NSManaged public var durationSec: Int32
    @NSManaged public var pages: Int32
    @NSManaged public var summary: String?
    @NSManaged public var attribution: String?
    @NSManaged public var tags: Data? // JSON encoded [String]
    
    // Relationships
    @NSManaged public var course: Course?
    @NSManaged public var lesson: Lesson?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContentItem> {
        return NSFetchRequest<ContentItem>(entityName: "ContentItem")
    }
    
    /// Get tags as string array
    public var tagsList: [String] {
        guard let tagsData = tags else { return [] }
        return (try? JSONSerialization.jsonObject(with: tagsData, options: [])) as? [String] ?? []
    }
    
    /// Set tags from string array
    public func setTags(_ tagsList: [String]) {
        self.tags = try? JSONSerialization.data(withJSONObject: tagsList, options: [])
    }
    
    /// Duration as TimeInterval
    public var duration: TimeInterval {
        return TimeInterval(durationSec)
    }
    
    /// Whether this is a video content
    public var isVideo: Bool {
        return type.lowercased() == "video"
    }
    
    /// Whether this is readable content
    public var isReadable: Bool {
        return ["article", "pdf", "book"].contains(type.lowercased())
    }
    
    /// Whether this is audio content
    public var isAudio: Bool {
        return type.lowercased() == "podcast"
    }
}

// MARK: - User Entity (for caching user data)
@objc(User)
public class User: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var avatarUrl: String?
    @NSManaged public var xp: Int32
    @NSManaged public var streak: Int32
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
}