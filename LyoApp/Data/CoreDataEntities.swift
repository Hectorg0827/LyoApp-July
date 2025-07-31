import CoreData
import Foundation

// MARK: - User Entity
@objc(UserEntity)
public class UserEntity: NSManagedObject {
    
}

extension UserEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var fullName: String?
    @NSManaged public var profileImageURL: String?
    @NSManaged public var bio: String?
    @NSManaged public var isVerified: Bool
    @NSManaged public var followerCount: Int32
    @NSManaged public var followingCount: Int32
    @NSManaged public var level: Int32
    @NSManaged public var experience: Int32
    @NSManaged public var joinDate: Date?
    @NSManaged public var lastLoginDate: Date?
    @NSManaged public var preferences: String? // JSON string for user preferences
    @NSManaged public var achievements: String? // JSON string for achievements array
    
    // Relationships
    @NSManaged public var posts: NSSet?
    @NSManaged public var courseEnrollments: NSSet?
    @NSManaged public var learningProgress: NSSet?
    @NSManaged public var stories: NSSet?
}

// MARK: - UserEntity+CoreDataGeneratedAccessors
extension UserEntity {
    
    @objc(addPostsObject:)
    @NSManaged public func addToPosts(_ value: PostEntity)
    
    @objc(removePostsObject:)
    @NSManaged public func removeFromPosts(_ value: PostEntity)
    
    @objc(addPosts:)
    @NSManaged public func addToPosts(_ values: NSSet)
    
    @objc(removePosts:)
    @NSManaged public func removeFromPosts(_ values: NSSet)
    
    @objc(addCourseEnrollmentsObject:)
    @NSManaged public func addToCourseEnrollments(_ value: CourseEnrollmentEntity)
    
    @objc(removeCourseEnrollmentsObject:)
    @NSManaged public func removeFromCourseEnrollments(_ value: CourseEnrollmentEntity)
    
    @objc(addCourseEnrollments:)
    @NSManaged public func addToCourseEnrollments(_ values: NSSet)
    
    @objc(removeCourseEnrollments:)
    @NSManaged public func removeFromCourseEnrollments(_ values: NSSet)
}

// MARK: - Post Entity
@objc(PostEntity)
public class PostEntity: NSManagedObject {
    
}

extension PostEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostEntity> {
        return NSFetchRequest<PostEntity>(entityName: "PostEntity")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var authorId: String?
    @NSManaged public var content: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var imageURLs: String? // Comma-separated URLs
    @NSManaged public var videoURL: String?
    @NSManaged public var likeCount: Int32
    @NSManaged public var commentCount: Int32
    @NSManaged public var shareCount: Int32
    @NSManaged public var isLiked: Bool
    @NSManaged public var location: String?
    @NSManaged public var tags: String? // Comma-separated tags
    
    // Relationships
    @NSManaged public var author: UserEntity?
}

// MARK: - Course Entity
@objc(CourseEntity)
public class CourseEntity: NSManagedObject {
    
}

extension CourseEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CourseEntity> {
        return NSFetchRequest<CourseEntity>(entityName: "CourseEntity")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var courseDescription: String?
    @NSManaged public var instructor: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var category: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var duration: Int32 // Duration in minutes
    @NSManaged public var price: Double
    @NSManaged public var rating: Double
    @NSManaged public var totalLessons: Int32
    @NSManaged public var createdDate: Date?
    @NSManaged public var updatedDate: Date?
    @NSManaged public var prerequisites: String? // JSON string
    @NSManaged public var learningOutcomes: String? // JSON string
    @NSManaged public var syllabus: String? // JSON string
    
    // Relationships
    @NSManaged public var enrollments: NSSet?
    @NSManaged public var lessons: NSSet?
}

// MARK: - Course Enrollment Entity
@objc(CourseEnrollmentEntity)
public class CourseEnrollmentEntity: NSManagedObject {
    
}

extension CourseEnrollmentEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CourseEnrollmentEntity> {
        return NSFetchRequest<CourseEnrollmentEntity>(entityName: "CourseEnrollmentEntity")
    }
    
    @NSManaged public var courseId: String?
    @NSManaged public var userId: String?
    @NSManaged public var enrollmentDate: Date?
    @NSManaged public var lastAccessDate: Date?
    @NSManaged public var completionDate: Date?
    @NSManaged public var progress: Double // 0.0 to 1.0
    @NSManaged public var isCompleted: Bool
    @NSManaged public var certificateEarned: Bool
    @NSManaged public var totalTimeSpent: Double // Time in seconds
    @NSManaged public var currentLessonId: String?
    
    // Relationships
    @NSManaged public var user: UserEntity?
    @NSManaged public var course: CourseEntity?
}

// MARK: - Video Entity
@objc(VideoEntity)
public class VideoEntity: NSManagedObject {
    
}

extension VideoEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<VideoEntity> {
        return NSFetchRequest<VideoEntity>(entityName: "VideoEntity")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var videoDescription: String?
    @NSManaged public var thumbnailURL: String?
    @NSManaged public var url: String?
    @NSManaged public var duration: Int32 // Duration in seconds
    @NSManaged public var category: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var instructor: String?
    @NSManaged public var viewCount: Int32
    @NSManaged public var rating: Double
    @NSManaged public var createdDate: Date?
    @NSManaged public var tags: String? // Comma-separated tags
}

// MARK: - Ebook Entity
@objc(EbookEntity)
public class EbookEntity: NSManagedObject {
    
}

extension EbookEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EbookEntity> {
        return NSFetchRequest<EbookEntity>(entityName: "EbookEntity")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var author: String?
    @NSManaged public var ebookDescription: String?
    @NSManaged public var coverImageURL: String?
    @NSManaged public var fileURL: String?
    @NSManaged public var category: String?
    @NSManaged public var pageCount: Int32
    @NSManaged public var fileSize: Int64 // Size in bytes
    @NSManaged public var language: String?
    @NSManaged public var publishedDate: Date?
    @NSManaged public var rating: Double
    @NSManaged public var downloadCount: Int32
}

// MARK: - Community Entity
@objc(CommunityEntity)
public class CommunityEntity: NSManagedObject {
    
}

extension CommunityEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CommunityEntity> {
        return NSFetchRequest<CommunityEntity>(entityName: "CommunityEntity")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var communityDescription: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var coverImageURL: String?
    @NSManaged public var memberCount: Int32
    @NSManaged public var category: String?
    @NSManaged public var isPrivate: Bool
    @NSManaged public var createdDate: Date?
    @NSManaged public var rules: String? // JSON string
    @NSManaged public var moderators: String? // JSON string array of user IDs
}

// MARK: - Story Entity
@objc(StoryEntity)
public class StoryEntity: NSManagedObject {
    
}

extension StoryEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryEntity> {
        return NSFetchRequest<StoryEntity>(entityName: "StoryEntity")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var userId: String?
    @NSManaged public var mediaURL: String?
    @NSManaged public var mediaType: String? // "image" or "video"
    @NSManaged public var caption: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var expiryDate: Date?
    @NSManaged public var isViewed: Bool
    @NSManaged public var viewCount: Int32
    @NSManaged public var duration: Int32 // Duration in seconds for videos
    
    // Relationships
    @NSManaged public var user: UserEntity?
}

// MARK: - Learning Progress Entity
@objc(LearningProgressEntity)
public class LearningProgressEntity: NSManagedObject {
    
}

extension LearningProgressEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LearningProgressEntity> {
        return NSFetchRequest<LearningProgressEntity>(entityName: "LearningProgressEntity")
    }
    
    @NSManaged public var resourceId: String?
    @NSManaged public var userId: String?
    @NSManaged public var resourceType: String? // "course", "video", "ebook"
    @NSManaged public var percentage: Double // 0.0 to 1.0
    @NSManaged public var timeSpent: Double // Time in seconds
    @NSManaged public var lastAccessed: Date?
    @NSManaged public var completed: Bool
    @NSManaged public var sessionCount: Int32
    @NSManaged public var notes: String?
    @NSManaged public var bookmarks: String? // JSON string array of timestamps/page numbers
    
    // Relationships
    @NSManaged public var user: UserEntity?
}
