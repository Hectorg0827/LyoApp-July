import Foundation

// MARK: - Auth Models
struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

// MARK: - Media Models
enum MediaKind: String, Codable {
    case image = "IMAGE"
    case video = "VIDEO"
    case audio = "AUDIO"
    case document = "DOCUMENT"
}

struct Presign: Codable {
    let uploadUrl: String
    let assetUrl: String
    let headers: [String: String]?
}

struct MediaMeta: Codable {
    let width: Int?
    let height: Int?
    let duration: Double?
    let size: Int64
    let thumbnailUrl: String?
}

struct MediaRef: Codable {
    let id: String
    let url: String
    let kind: MediaKind
    let meta: MediaMeta?
}

// MARK: - Feed Models
struct CreatePost: Codable {
    let text: String?
    let mediaIds: [String]
    let mentions: [String]?
    let hashtags: [String]?
}

struct FeedItem: Codable, Identifiable {
    let id: String
    let authorId: String
    let author: Profile?
    let text: String?
    let media: [MediaRef]
    let reactions: [String: Int]
    let commentCount: Int
    let shareCount: Int
    let createdAt: Date
    let userReaction: ReactionType?
}

enum ReactionType: String, Codable {
    case like = "LIKE"
    case love = "LOVE"
    case laugh = "LAUGH"
    case wow = "WOW"
    case sad = "SAD"
    case angry = "ANGRY"
}

// MARK: - Story Models
struct StoryReel: Codable, Identifiable {
    let id: String
    let userId: String
    let user: Profile?
    let stories: [Story]
    let hasUnviewed: Bool
}

struct Story: Codable, Identifiable {
    let id: String
    let mediaUrl: String
    let caption: String?
    let createdAt: Date
    let viewCount: Int
    let isViewed: Bool
}

// MARK: - Messaging Models
enum ChatType: String, Codable {
    case direct = "DIRECT"
    case group = "GROUP"
}

struct Message: Codable, Identifiable {
    let id: String
    let chatId: String
    let senderId: String
    let text: String?
    let media: MediaRef?
    let createdAt: Date
    let readBy: [String]
}

enum MessageEvent: Codable {
    case newMessage(Message)
    case typing(userId: String)
    case read(messageId: String, userId: String)
    case deleted(messageId: String)
}

// MARK: - Notification Models
struct AppNotification: Codable, Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let data: [String: String]?
    let createdAt: Date
    let isRead: Bool
}

enum NotificationType: String, Codable {
    case newFollower = "NEW_FOLLOWER"
    case postLike = "POST_LIKE"
    case postComment = "POST_COMMENT"
    case mention = "MENTION"
    case directMessage = "DIRECT_MESSAGE"
    case courseUpdate = "COURSE_UPDATE"
}

// MARK: - Tutor Models
struct TutorTurn: Codable {
    let role: TutorRole
    let content: String
    let context: TutorContext?
}

enum TutorRole: String, Codable {
    case user = "USER"
    case assistant = "ASSISTANT"
    case system = "SYSTEM"
}

struct TutorContext: Codable {
    let learnerId: String
    let currentLesson: String?
    let history: [TutorTurn]
    let learnerProfile: LearnerProfile?
}

struct LearnerProfile: Codable {
    let level: String
    let strengths: [String]
    let weaknesses: [String]
    let preferredStyle: String
}

enum TutorEvent: Codable {
    case text(String)
    case thinking(String)
    case complete
    case error(String)
}

// MARK: - Course Planner Models
struct LearningGoal: Codable {
    let title: String
    let description: String
    let targetDate: Date?
    let skillLevel: String
}

struct CoursePlan: Codable, Identifiable {
    let id: String
    let goal: LearningGoal
    let lessons: [Lesson]
    let progress: Double
    let estimatedDuration: Int
}

struct LessonContent: Codable {
    let type: ContentType
    let data: String
}

enum ContentType: String, Codable {
    case text = "TEXT"
    case video = "VIDEO"
    case interactive = "INTERACTIVE"
    case quiz = "QUIZ"
}

enum LessonStatus: String, Codable {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
}

struct QuizItem: Codable, Identifiable {
    let id: String
    let question: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String?
}

struct QuizResult: Codable {
    let quizId: String
    let lessonId: String
    let score: Double
    let answers: [QuizAnswer]
}

struct QuizAnswer: Codable {
    let questionId: String
    let selectedOption: Int
    let isCorrect: Bool
    let timeSpent: Double
}

// MARK: - Search Models
enum SearchType: String, Codable {
    case users = "USERS"
    case posts = "POSTS"
    case courses = "COURSES"
    case all = "ALL"
}

struct SearchResults: Codable {
    let users: [Profile]?
    let posts: [FeedItem]?
    let courses: [Course]?
    let nextCursor: String?
}

struct TrendingResults: Codable {
    let hashtags: [TrendingHashtag]
    let topics: [TrendingTopic]
}

struct TrendingHashtag: Codable {
    let tag: String
    let postCount: Int
    let trend: TrendDirection
}

struct TrendingTopic: Codable {
    let title: String
    let description: String
    let postCount: Int
    let trend: TrendDirection
}

enum TrendDirection: String, Codable {
    case up = "UP"
    case down = "DOWN"
    case stable = "STABLE"
}

// MARK: - Helper Response Types
struct EmptyResponse: Codable {}
struct CreatePostResponse: Codable { let postId: String }
struct FeedResponse: Codable { let items: [FeedItem]; let nextCursor: String? }
struct CommentResponse: Codable { let commentId: String }
