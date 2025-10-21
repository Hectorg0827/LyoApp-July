import Foundation

// MARK: - Authentication Models

struct RegisterRequest: Encodable {
    let username: String
    let email: String
    let password: String
    let fullName: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct AuthResponse: Decodable {
    let userId: Int
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int?
}

struct UserProfile: Decodable {
    let userId: Int
    let username: String
    let email: String
    let fullName: String
    let avatarUrl: String?
    let bio: String?
    let createdAt: String
}

// MARK: - Course Generation Models

struct GenerateCourseRequest: Encodable {
    let topic: String
    let level: String  // "beginner", "intermediate", "advanced"
    let outcomes: [String]
    let teachingStyle: String  // "examples-first", "theory-first", "project-based", "balanced"
    let minutesPerDay: Int?
    let daysPerWeek: Int?
}

struct GenerateCourseResponse: Decodable {
    let courseId: String
    let title: String
    let topic: String
    let level: String
    let modules: [CourseModuleDTO]
    let estimatedDurationHours: Int
    let createdAt: String
}

struct CourseModuleDTO: Decodable, Identifiable {
    let id: String
    let title: String
    let description: String
    let order: Int
    let lessons: [LessonDTO]
    let estimatedMinutes: Int
}

struct LessonDTO: Decodable, Identifiable {
    let id: String
    let title: String
    let description: String
    let order: Int
    let moduleId: String
    let content: LessonContentDTO?
    let estimatedMinutes: Int
    let difficulty: String
}

struct LessonContentDTO: Decodable {
    let introduction: String?
    let videoUrl: String?
    let wikipediaSummary: String?
    let examples: [String]?
    let practiceExercises: [ExerciseDTO]?
    let keyPoints: [String]?
    let resources: [ResourceDTO]?
}

struct ExerciseDTO: Decodable, Identifiable {
    let id: String
    let question: String
    let type: String  // "multiple_choice", "code", "open_ended"
    let options: [String]?
    let correctAnswer: String?
    let explanation: String?
}

struct ResourceDTO: Decodable, Identifiable {
    let id: String
    let type: String  // "video", "article", "book", "tool"
    let title: String
    let url: String
    let source: String
    let duration: String?
    let thumbnail: String?
}

// MARK: - Lesson Assembly Models

struct AssembleLessonRequest: Encodable {
    let topic: String
    let level: String
    let learningObjectives: [String]
    let contentPreferences: ContentPreferences?
}

struct ContentPreferences: Encodable {
    let preferVideo: Bool?
    let maxDurationMinutes: Int?
    let includeExercises: Bool?
    let sources: [String]?  // ["youtube", "wikipedia", "books"]
}

struct AssembleLessonResponse: Decodable {
    let lessonId: String
    let topic: String
    let content: LessonContentDTO
    let estimatedMinutes: Int
    let sources: [String]
}

// MARK: - AI Chat Models

struct AIChatRequest: Encodable {
    let userId: Int
    let message: String
    let model: String  // "gemini-2.0-flash-exp", "gpt-4", "claude-3"
    let context: ChatContext?
}

struct ChatContext: Encodable {
    let currentLesson: String?
    let userLevel: String?
    let avatarPersonality: String?
    let conversationId: String?
}

struct AIChatResponse: Decodable {
    let response: String
    let modelUsed: String
    let tokensUsed: Int?
    let responseTimeMs: Int?
    let conversationId: String?
}

struct ConversationHistory: Decodable {
    let conversations: [ConversationDTO]
}

struct ConversationDTO: Decodable, Identifiable {
    let id: String
    let userId: Int
    let messages: [MessageDTO]
    let createdAt: String
    let updatedAt: String
}

struct MessageDTO: Decodable, Identifiable {
    let id: String
    let role: String  // "user" or "assistant"
    let content: String
    let timestamp: String
    let model: String?
}

// MARK: - Progress Tracking Models

struct CompleteLessonRequest: Encodable {
    let userId: Int
    let lessonId: String
    let timeSpentMinutes: Int
    let score: Int?
    let struggledWith: [String]?
}

struct CompleteLessonResponse: Decodable {
    let success: Bool
    let xpEarned: Int
    let progress: UserProgressDTO
}

struct UserProgressDTO: Decodable {
    let courseId: String
    let completionPercentage: Int
    let lessonsCompleted: Int
    let lessonsTotal: Int
    let timeSpentMinutes: Int
    let currentLesson: String?
    let lastAccessedAt: String
}

struct ProgressResponse: Decodable {
    let courses: [CourseProgressDTO]
    let totalTimeMinutes: Int
    let totalLessonsCompleted: Int
}

struct CourseProgressDTO: Decodable, Identifiable {
    let id: String
    let courseId: String
    let courseName: String
    let progress: UserProgressDTO
}

// MARK: - Gamification Models

struct GamificationProfile: Decodable {
    let userId: Int
    let level: Int
    let xp: Int
    let xpToNextLevel: Int
    let rank: String
    let totalAchievements: Int
}

struct LogActivityRequest: Encodable {
    let userId: Int
    let activityType: String  // "lesson_completed", "quiz_passed", "daily_login", "streak_milestone"
    let metadata: [String: String]?
}

struct LogActivityResponse: Decodable {
    let xpEarned: Int
    let newLevel: Bool
    let currentLevel: Int
    let newAchievements: [AchievementDTO]
}

struct AchievementDTO: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let unlockedAt: String?
    let progress: Int?
    let requirement: Int?
}

struct LeaderboardResponse: Decodable {
    let rankings: [LeaderboardEntry]
    let userRank: Int?
}

struct LeaderboardEntry: Decodable, Identifiable {
    let id: Int
    let rank: Int
    let userId: Int
    let username: String
    let xp: Int
    let level: Int
    let avatarUrl: String?
}

struct StreakResponse: Decodable {
    let currentStreak: Int
    let longestStreak: Int
    let lastActivityDate: String
}

// MARK: - File Upload Models

struct FileUploadRequest: Encodable {
    let userId: Int
    let fileType: String  // "avatar", "lesson_media", "profile_image"
}

struct FileUploadResponse: Decodable {
    let fileId: String
    let url: String
    let sizeBytes: Int
    let mimeType: String
}

// MARK: - Search Models

struct SearchRequest: Encodable {
    let query: String
    let userId: Int?
    let types: [String]?  // ["courses", "lessons", "users", "posts"]
    let limit: Int?
}

struct SearchResponse: Decodable {
    let users: [UserProfile]?
    let courses: [GenerateCourseResponse]?
    let lessons: [LessonDTO]?
    let posts: [PostDTO]?
}

struct PostDTO: Decodable, Identifiable {
    let id: String
    let userId: Int
    let content: String
    let createdAt: String
    let likeCount: Int
    let commentCount: Int
}

// MARK: - Health Check Models

struct HealthResponse: Decodable {
    let status: String
    let version: String?
    let timestamp: String
}

struct AIHealthResponse: Decodable {
    let status: String
    let availableModels: [String]
    let responseTimeMs: Int
}

struct ContentHealthResponse: Decodable {
    let status: String
    let services: ServiceStatus
}

struct ServiceStatus: Decodable {
    let wikipedia: Bool
    let youtube: Bool
    let geminiAi: Bool
}

// MARK: - WebSocket Message Models

struct WebSocketMessage: Codable {
    let type: String
    let data: [String: String]?
    let timestamp: String?
}

// AI Chat WebSocket events
struct AIChatEvent: Codable {
    let type: String  // "ai_response", "ai_thinking", "ai_error"
    let message: String?
    let tokens: Int?
    let conversationId: String?
}

// Course Generation Progress events
struct CourseGenerationProgress: Codable {
    let type: String  // "task_progress", "task_complete", "task_error"
    let taskId: String
    let progress: Int?  // 0-100
    let status: String?
    let message: String?
    let courseId: String?
}

// Messaging WebSocket events
struct MessagingEvent: Codable {
    let type: String  // "new_message", "typing", "read_receipt", "online_status"
    let conversationId: String?
    let message: MessageDTO?
    let userId: Int?
    let isTyping: Bool?
}

// Notification WebSocket events
struct NotificationEvent: Codable {
    let type: String  // "notification", "badge_update"
    let notification: NotificationDTO?
    let badgeCount: Int?
}

struct NotificationDTO: Codable, Identifiable {
    let id: String
    let userId: Int
    let title: String
    let body: String
    let category: String
    let data: [String: String]?
    let createdAt: String
}

// MARK: - Push Notification Models

struct RegisterDeviceRequest: Encodable {
    let userId: Int
    let deviceToken: String
    let platform: String  // "ios" or "android"
    let deviceModel: String
    let osVersion: String
}

struct RegisterDeviceResponse: Decodable {
    let success: Bool
    let deviceId: String
}

struct NotificationPreferences: Codable {
    let notificationsEnabled: Bool
    let lessonReminders: Bool
    let achievementUnlocked: Bool
    let newMessages: Bool
    let dailyStreak: Bool
}

struct UpdatePreferencesRequest: Encodable {
    let userId: Int
    let preferences: NotificationPreferences
}

// MARK: - Enroll Course Model

struct EnrollCourseRequest: Encodable {
    let userId: Int
    let courseId: String
}

struct EnrollCourseResponse: Decodable {
    let success: Bool
    let enrollmentId: String
    let course: GenerateCourseResponse
}
