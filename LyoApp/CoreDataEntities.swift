import Foundation
import CoreData

// MARK: - Core Data Entity Classes (Placeholder)

@objc(CoreDataUserEntity)
public class CoreDataUserEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var username: String
    @NSManaged public var email: String
    @NSManaged public var fullName: String
    @NSManaged public var bio: String?
    @NSManaged public var followers: Int32
    @NSManaged public var following: Int32
    @NSManaged public var posts: Int32
    @NSManaged public var createdAt: Date
}

@objc(PostEntity)  
public class PostEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var content: String
    @NSManaged public var authorId: String
    @NSManaged public var createdAt: Date
    @NSManaged public var likes: Int32
    @NSManaged public var comments: Int32
}

@objc(CourseEntity)
public class CourseEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var desc: String
    @NSManaged public var instructor: String
    @NSManaged public var duration: String
    @NSManaged public var rating: Double
    @NSManaged public var enrollmentCount: Int32
    @NSManaged public var createdAt: Date
}

@objc(CourseEnrollmentEntity)
public class CourseEnrollmentEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var userId: String
    @NSManaged public var courseId: String
    @NSManaged public var progress: Double
    @NSManaged public var enrolledAt: Date
    @NSManaged public var completedAt: Date?
}

@objc(ContentItemEntity)
public class ContentItemEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var type: String?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var duration: TimeInterval
    @NSManaged public var courseId: String?
    @NSManaged public var order: Int32
    @NSManaged public var createdAt: Date?
}

@objc(VideoEntity)
public class VideoEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var url: String
    @NSManaged public var duration: Int32
    @NSManaged public var courseId: String?
    @NSManaged public var createdAt: Date
}

@objc(StoryEntity)
public class StoryEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var userId: String
    @NSManaged public var mediaUrl: String
    @NSManaged public var mediaType: String
    @NSManaged public var createdAt: Date
    @NSManaged public var expiresAt: Date
}
