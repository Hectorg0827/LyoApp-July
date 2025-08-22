import Foundation

// MARK: - Course DTO (from API)
struct CourseDTO: Decodable {
    let id: String
    let title: String
    let topic: String
    let summary: String?
    let status: String
    let createdAt: Date
    let ownerUserId: String
    let lessons: [LessonDTO]
    let items: [ContentItemDTO]
    
    enum CodingKeys: String, CodingKey {
        case id, title, topic, summary, status
        case createdAt = "created_at"
        case ownerUserId = "owner_user_id"
        case lessons, items
    }
}

// MARK: - Lesson DTO (from API)
struct LessonDTO: Decodable {
    let id: String
    let title: String
    let order: Int
    let summary: String?
    let courseId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, order, summary
        case courseId = "course_id"
    }
}

// MARK: - Content Item DTO (from API)
struct ContentItemDTO: Decodable {
    let id: String
    let type: String
    let title: String
    let source: String
    let sourceUrl: String
    let thumbnailUrl: String?
    let durationSec: Int?
    let pages: Int?
    let summary: String?
    let attribution: String?
    let tags: [String]?
    let courseId: String?
    let lessonId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, source, summary, attribution, tags
        case sourceUrl = "source_url"
        case thumbnailUrl = "thumbnail_url"  
        case durationSec = "duration_sec"
        case pages
        case courseId = "course_id"
        case lessonId = "lesson_id"
    }
}

// MARK: - User DTO (from API)
struct UserDTO: Decodable {
    let id: String
    let name: String
    let avatarUrl: String?
    let xp: Int
    let streak: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, xp, streak
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Feed Response DTO
struct FeedResponse: Decodable {
    let items: [FeedItemDTO]
    let nextCursor: String?
    
    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
    }
}

// MARK: - Feed Item DTO
struct FeedItemDTO: Decodable {
    let id: String
    let type: String
    let title: String?
    let content: String?
    let imageUrl: String?
    let author: UserDTO?
    let course: CourseDTO?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, content, author, course
        case imageUrl = "image_url"
        case createdAt = "created_at"
    }
}

// MARK: - Community Response DTO
struct CommunityResponse: Decodable {
    let discussions: [DiscussionDTO]
    let nextCursor: String?
    
    enum CodingKeys: String, CodingKey {
        case discussions
        case nextCursor = "next_cursor"
    }
}

// MARK: - Discussion DTO
struct DiscussionDTO: Decodable {
    let id: String
    let title: String
    let content: String
    let author: UserDTO
    let tags: [String]
    let likes: Int
    let replies: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, author, tags, likes, replies
        case createdAt = "created_at"
    }
}