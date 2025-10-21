import Foundation

// MARK: - User-related models (avoiding conflicts with canonical versions)
// Using unique names to avoid redeclaration errors

// MARK: - Social Feed Post Model 
struct SocialFeedPost: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let username: String
    let userAvatar: URL?
    let content: String
    let imageURLs: [URL]?
    let videoURL: URL?
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let isLiked: Bool
    let isBookmarked: Bool
    let createdAt: String
    let tags: [String]?
}

// MARK: - Create Post Request
// Duplicate removed; canonical definition lives in APIResponseModels.swift

// MARK: - User Achievement Model
struct UserAchievement: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let iconName: String
    let dateEarned: Date
    let progress: Double?
    let isCompleted: Bool
}

// MARK: - User Study Plan
struct UserStudyPlan: Identifiable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var courseIds: [UUID]
    var progress: Double = 0.0
    var isActive: Bool = true
}

// MARK: - Chat Message
// Duplicate removed; using unified AIMessage via typealias ChatMessage = AIMessage in Models.swift

// MARK: - User Learning Resource
struct UserLearningResource: Identifiable, Hashable {
    public let id: String
    public var title: String
    public var description: String
    public var type: ResourceType
    public var thumbnailUrl: URL?
    public var sourceUrl: URL?
    public var tags: [String]?
    public var difficulty: String?
    public var duration: Int?  // in minutes
    public var rating: Double?
    public var isFavorite: Bool
    public var isDownloaded: Bool
    public var lastViewedAt: Date?
    public var createdAt: Date
    
    public enum ResourceType: String, Codable {
        case video
        case article
        case quiz
        case exercise
        case course
        case ebook
    }
    
    public enum DifficultyLevel: String {
        case beginner
        case intermediate
        case advanced
        case all
        
        public var displayText: String {
            switch self {
            case .beginner: return "Beginner"
            case .intermediate: return "Intermediate"
            case .advanced: return "Advanced"
            case .all: return "All Levels"
            }
        }
    }
    
    public static func sampleResources() -> [UserLearningResource] {
        return [
            UserLearningResource(
                id: "resource1",
                title: "Introduction to Machine Learning",
                description: "Learn the basics of machine learning algorithms and their applications.",
                type: .video,
                thumbnailUrl: URL(string: "https://example.com/ml-intro.jpg"),
                sourceUrl: URL(string: "https://example.com/ml-intro"),
                tags: ["Machine Learning", "AI", "Data Science"],
                difficulty: "beginner",
                duration: 45,
                rating: 4.8,
                isFavorite: true,
                isDownloaded: false,
                lastViewedAt: Date().addingTimeInterval(-86400),
                createdAt: Date().addingTimeInterval(-604800)
            ),
            UserLearningResource(
                id: "resource2",
                title: "Advanced Python Programming",
                description: "Deep dive into Python advanced features like decorators, generators, and more.",
                type: .course,
                thumbnailUrl: URL(string: "https://example.com/python-advanced.jpg"),
                sourceUrl: URL(string: "https://example.com/python-advanced"),
                tags: ["Python", "Programming", "Software Development"],
                difficulty: "advanced",
                duration: 180,
                rating: 4.9,
                isFavorite: false,
                isDownloaded: true,
                lastViewedAt: nil,
                createdAt: Date().addingTimeInterval(-1209600)
            )
        ]
    }
}

// Define the AI quiz models (renamed to avoid conflicts)
struct UserAIQuizQuestion: Identifiable, Equatable, Hashable {
    public let id: UUID
    public let question: String
    public let options: [String]
    public let correctOptionIndex: Int
    public let explanation: String
    public let difficulty: Int
    
    public var correctAnswer: String {
        return options[correctOptionIndex]
    }
}

struct UserAIQuizOption: Identifiable, Hashable {
    public let id: UUID
    public let text: String
    public let isCorrect: Bool
}

// Removed LegacyLearningResource alias to avoid ambiguity with separate definition
typealias ModelsUserStudyProgram = UserStudyPlan
typealias ModelsUserAchievement = UserAchievement
