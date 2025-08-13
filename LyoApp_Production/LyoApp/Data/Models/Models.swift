import Foundation

// MARK: - User Model (matching backend structure)
struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let name: String
    let username: String?
    let avatarUrl: String?
    let bio: String?
    let createdAt: String?
    let updatedAt: String?
    let isVerified: Bool?
    let stats: UserStats?
    let preferences: UserPreferences?
    
    // Computed properties for compatibility
    var fullName: String { name }
    var profileImageURL: String? { avatarUrl }
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, username, bio, createdAt, updatedAt, isVerified, stats, preferences
        case avatarUrl = "avatar_url"
    }
}

struct UserStats: Codable {
    let totalCourses: Int
    let completedCourses: Int
    let totalPoints: Int
    let level: Int
    let streak: Int
    let totalStudyHours: Double
}

struct UserPreferences: Codable {
    let theme: String
    let language: String
    let notificationsEnabled: Bool
    let studyReminders: Bool
    let weeklyGoalHours: Int
}

// MARK: - Course Model (matching backend structure)
struct Course: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String?
    let duration: Int // in minutes
    let difficulty: String // "beginner", "intermediate", "advanced"
    let category: String
    let instructor: CourseInstructor
    let price: Double
    let currency: String
    let rating: Double
    let totalRatings: Int
    let totalEnrollments: Int
    let createdAt: String
    let updatedAt: String
    let isPublished: Bool
    let chapters: [CourseChapter]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, duration, difficulty, category, instructor, price, currency, rating, createdAt, updatedAt, isPublished, chapters
        case thumbnailURL = "thumbnailUrl"
        case totalRatings = "totalRatings"
        case totalEnrollments = "totalEnrollments"
    }
}

struct CourseInstructor: Codable {
    let id: String
    let name: String
    let bio: String?
    let profileImageURL: String?
    let rating: Double
    let totalCourses: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, bio, rating, totalCourses
        case profileImageURL = "profileImageUrl"
    }
}

struct CourseChapter: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let duration: Int
    let orderIndex: Int
    let isCompleted: Bool?
    let videoURL: String?
    let resources: [CourseResource]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, duration, orderIndex, isCompleted, resources
        case videoURL = "videoUrl"
    }
}

struct CourseResource: Codable, Identifiable {
    let id: String
    let title: String
    let type: String // "pdf", "link", "video", "quiz"
    let url: String
    let downloadable: Bool
}

// MARK: - Feed Models
struct FeedPost: Codable, Identifiable {
    let id: String
    let userId: String
    let user: User
    let content: String
    let mediaURL: String?
    let mediaType: String? // "image", "video"
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let createdAt: String
    let updatedAt: String
    let isLiked: Bool?
    let tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, user, content, mediaType, likesCount, commentsCount, sharesCount, createdAt, updatedAt, isLiked, tags
        case mediaURL = "mediaUrl"
    }
}

struct FeedComment: Codable, Identifiable {
    let id: String
    let postId: String
    let userId: String
    let user: User
    let content: String
    let createdAt: String
    let likesCount: Int
    let isLiked: Bool?
}

// MARK: - AI Models
struct AIChat: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let messages: [AIChatMessage]
    let createdAt: String
    let updatedAt: String
    let isActive: Bool
}

struct AIChatMessage: Codable, Identifiable {
    let id: String
    let chatId: String
    let role: String // "user", "assistant"
    let content: String
    let timestamp: String
    let metadata: MessageMetadata?
}

struct MessageMetadata: Codable {
    let tokensUsed: Int?
    let processingTime: Double?
    let confidence: Double?
}

// MARK: - Community Models
struct Community: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let imageURL: String?
    let memberCount: Int
    let isPublic: Bool
    let category: String
    let createdAt: String
    let isMember: Bool?
    let moderators: [User]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, memberCount, isPublic, category, createdAt, isMember, moderators
        case imageURL = "imageUrl"
    }
}

// MARK: - Gamification Models
struct Badge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let iconURL: String
    let category: String
    let points: Int
    let rarity: String // "common", "rare", "epic", "legendary"
    let earnedAt: String?
    let isEarned: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, points, rarity, earnedAt, isEarned
        case iconURL = "iconUrl"
    }
}

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let user: User
    let points: Int
    let rank: Int
    let change: Int // +/- from previous period
    let period: String // "weekly", "monthly", "all-time"
}
