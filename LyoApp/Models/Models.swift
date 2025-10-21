import Foundation
// File touched to force Xcode to invalidate any stale duplicate symbol cache (AIMessage / ChatConversation)
import SwiftUI
import SwiftData

// MARK: - CORE TYPES (Must be at top for compilation order)
// These types are used across the entire app and must be compiled first

// MARK: - AI Message (Chat & Conversations)

public struct AIMessage: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let content: String
    public let isFromUser: Bool
    public let timestamp: Date
    public let messageType: MessageType
    public let interactionId: Int?
    
    public enum MessageType: String, Codable {
        case text, code, explanation, quiz, resource, system
    }
    
    public init(
        id: UUID = UUID(),
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        messageType: MessageType = .text,
        interactionId: Int? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.messageType = messageType
        self.interactionId = interactionId
    }
}

public typealias ChatMessage = AIMessage

// MARK: - AI Message Metadata

public struct AIMessageMetadata: Codable, Equatable {
    public var suggestions: [String]?
    public var resources: [LearningResource]?
    public var mood: String?

    public init(suggestions: [String]? = nil, resources: [LearningResource]? = nil, mood: String? = nil) {
        self.suggestions = suggestions
        self.resources = resources
        self.mood = mood
    }
}

// Bridging extension for legacy code expecting `sender: String` instead of `isFromUser: Bool`
extension AIMessage {
    public var sender: String { isFromUser ? "user" : "ai" }
    public init(content: String, sender: String, timestamp: Date = Date(), messageType: MessageType = .text) {
        self.init(content: content, isFromUser: sender == "user", timestamp: timestamp, messageType: messageType)
    }
}

// MARK: - Avatar System Types

public enum AvatarStyle: String, Codable, CaseIterable, Identifiable {
    case friendlyBot = "Friendly Bot"
    case wiseMentor = "Wise Mentor"
    case energeticCoach = "Energetic Coach"
    
    public var id: String { rawValue }
    
    public var emoji: String {
        switch self {
        case .friendlyBot: return "🤖"
        case .wiseMentor: return "🧙‍♂️"
        case .energeticCoach: return "🦁"
        }
    }
    
    public var gradientColors: [Color] {
        switch self {
        case .friendlyBot: return [.blue.opacity(0.7), .cyan.opacity(0.5)]
        case .wiseMentor: return [.purple.opacity(0.7), .indigo.opacity(0.5)]
        case .energeticCoach: return [.orange.opacity(0.7), .yellow.opacity(0.5)]
        }
    }
}

public enum Personality: String, Codable, CaseIterable, Identifiable {
    case friendlyCurious = "Lyo"
    case energeticCoach = "Max"
    case calmReflective = "Luna"
    case wisePatient = "Sage"
    
    public var id: String { rawValue }
}

public enum CompanionMood: String, Codable {
    case neutral, excited, encouraging, thoughtful, celebrating, tired, curious
}

public struct CompanionState: Codable {
    public var mood: CompanionMood = .neutral
    public var energy: Float = 1.0
    public var lastInteraction: Date = Date()
    public var currentActivity: String? = nil
    public var isSpeaking: Bool = false
    
    public init() {}
}

public struct AvatarMemory: Codable {
    public var lastSeenDate: Date = Date()
    public var topicsDiscussed: [String] = []
    public var strugglesNoted: [String: Int] = [:]
    public var achievements: [String] = []
    public var conversationCount: Int = 0
    public var totalStudyMinutes: Int = 0
    
    public init() {}
    
    public var mostChallengingTopic: String? {
        strugglesNoted.max(by: { $0.value < $1.value })?.key
    }
}

public enum UserAction {
    case answeredCorrect, answeredIncorrect, struggled, askedQuestion, completedLesson, startedSession
}

// MARK: - Avatar Supporting Types (must be before Avatar struct)

public enum ScaffoldingStyle: String, Codable {
    case examplesFirst = "examples"
    case theoryFirst = "theory"
    case challengeBased = "challenges"
    case balanced = "balanced"
}

public struct PersonalityProfile: Codable, Hashable {
    public var basePersonality: Personality
    public var hintFrequency: Float = 0.5
    public var celebrationIntensity: Float = 0.7
    public var pacePreference: Float = 0.5
    public var scaffoldingStyle: ScaffoldingStyle = .balanced
    
    public init(basePersonality: Personality = .friendlyCurious) {
        self.basePersonality = basePersonality
    }
}

public struct AvatarAppearance: Codable, Hashable {
    public var style: AvatarStyle = .friendlyBot
    public var skinTone: Int = 4
    public var faceShape: Int = 2
    public var eyeShape: Int = 1
    public var eyeColor: Int = 3
    public var hairStyle: Int = 4
    public var hairColor: Int = 3
    public var accessories: [Int] = []
    public var outfit: Int = 1
    
    public init() {}
}

public struct CalibrationAnswers: Codable, Hashable {
    public var learningStyle: ScaffoldingStyle = .balanced
    public var pace: String = "balanced"
    public var motivation: String = "encouragement"
    public var challengePreference: String = "moderate"
    
    public init() {}
}

public struct Avatar: Codable, Identifiable, Hashable {
    public var id: UUID = UUID()
    public var name: String = "Lyo"
    public var appearance: AvatarAppearance = AvatarAppearance()
    public var profile: PersonalityProfile = PersonalityProfile(basePersonality: .friendlyCurious)
    public var voiceIdentifier: String? = nil
    public var calibrationAnswers: CalibrationAnswers = CalibrationAnswers()
    public var createdAt: Date = Date()
    
    public var personality: Personality {
        profile.basePersonality
    }
    
    public var style: AvatarStyle {
        appearance.style
    }
    
    public init() {}
}

// MARK: - Learning Blueprint Types

public struct LearningBlueprint: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let nodes: [BlueprintNode]
    public let connectionPath: [String]
    public let createdAt: Date
    public let completionPercentage: Double
    public var learningGoals: String
    public var preferredStyle: String
    public var timeline: Int?
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        nodes: [BlueprintNode] = [],
        connectionPath: [String] = [],
        createdAt: Date = Date(),
        completionPercentage: Double = 0.0,
        learningGoals: String = "",
        preferredStyle: String = "",
        timeline: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.nodes = nodes
        self.connectionPath = connectionPath
        self.createdAt = createdAt
        self.completionPercentage = completionPercentage
        self.learningGoals = learningGoals
        self.preferredStyle = preferredStyle
        self.timeline = timeline
    }
}

public struct BlueprintNode: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let topic: String
    public let type: BlueprintNodeType
    public let description: String
    public let position: CGPoint
    public let isCompleted: Bool
    public let dependencies: [UUID]
    public let estimatedTime: TimeInterval
    
    public init(
        id: UUID = UUID(),
        title: String,
        topic: String,
        type: BlueprintNodeType = .lesson,
        description: String = "",
        position: CGPoint = .zero,
        isCompleted: Bool = false,
        dependencies: [UUID] = [],
        estimatedTime: TimeInterval = 300
    ) {
        self.id = id
        self.title = title
        self.topic = topic
        self.type = type
        self.description = description
        self.position = position
        self.isCompleted = isCompleted
        self.dependencies = dependencies
        self.estimatedTime = estimatedTime
    }
}

public enum BlueprintNodeType: String, Codable {
    case lesson, quiz, practice, project, review, assessment
}

// MARK: - END CORE TYPES
// Note: Avatar struct is defined in AvatarModels.swift with all its properties

// MARK: - User

public struct User: Identifiable, Codable, Hashable {
    public let id: UUID
    public var username: String
    public var email: String
    public var fullName: String
    public var bio: String?
    public var profileImageURL: URL?
    public var followers: Int = 0
    public var following: Int = 0
    // Restored legacy property used by some older views (e.g. AuthenticationView)
    var posts: Int = 0
    var isVerified: Bool = false
    var joinedAt: Date?
    var lastActiveAt: Date?
    var experience: Int = 0
    var level: Int = 1
    
    init(id: UUID = UUID(), username: String, email: String, fullName: String, bio: String? = nil,
         profileImageURL: URL? = nil, followers: Int = 0, following: Int = 0, posts: Int = 0,
         isVerified: Bool = false, joinedAt: Date? = nil, lastActiveAt: Date? = nil, experience: Int = 0, level: Int = 1) {
        self.id = id
        self.username = username
        self.email = email
        self.fullName = fullName
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.followers = followers
        self.following = following
        self.posts = posts
        self.isVerified = isVerified
        self.joinedAt = joinedAt
        self.lastActiveAt = lastActiveAt
        self.experience = experience
        self.level = level
    }
}

// MARK: - Study Program

struct StudyProgram: Identifiable, Hashable {
    public let id: UUID
    var title: String
    var description: String
    var duration: Int // In minutes
    var difficulty: String // "beginner", "intermediate", "advanced"
    var courseIds: [UUID]
    var thumbnailURL: URL?
    var progress: Double = 0.0
    var isEnrolled: Bool = false
}

// MARK: - Feed Course (simplified course for social feed)
// Note: Full course model is in ClassroomModels.swift
struct FeedCourse: Identifiable, Hashable, Codable {
    public let id: UUID
    var title: String
    var description: String
    var instructor: String
    var duration: Int // In minutes
    var createdAt: Date
    var updatedAt: Date
    
    enum Difficulty: String, Codable {
        case beginner
        case intermediate
        case advanced
    }
}

// MARK: - API Course Model (for backend integration)
struct APICourse: Codable, Identifiable {
    public let id: String
    public let title: String
    public let description: String
    let instructor: String
    let duration: Int
    let difficulty: String
    let category: String?
    let tags: [String]? // Added missing tags property
    let thumbnailUrl: String?
    let thumbnailURL: URL? // For compatibility
    let isEnrolled: Bool
    let progress: Double?
    let createdAt: String
    let updatedAt: String
    
    init(id: String = UUID().uuidString, title: String, description: String, instructor: String, 
         duration: Int, difficulty: String, category: String? = nil, tags: [String]? = nil,
         thumbnailUrl: String? = nil, isEnrolled: Bool = false, progress: Double? = nil, 
         createdAt: String = ISO8601DateFormatter().string(from: Date()),
         updatedAt: String = ISO8601DateFormatter().string(from: Date())) {
        self.id = id
        self.title = title
        self.description = description
        self.instructor = instructor
        self.duration = duration
        self.difficulty = difficulty
        self.category = category
        self.tags = tags
        self.thumbnailUrl = thumbnailUrl
        self.thumbnailURL = URL(string: thumbnailUrl ?? "")
        self.isEnrolled = isEnrolled
        self.progress = progress
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - API Study Program

struct APIStudyProgram: Codable, Identifiable {
    public let id: String
    public let title: String
    let isEnrolled: Bool?
}
// MARK: - Post Model

public struct Post: Identifiable, Hashable, Codable {
    public let id: UUID
    public let author: User
    public var content: String
    public var imageURLs: [URL]?
    public var videoURL: URL?
    public var likes: Int
    public var comments: Int
    public var shares: Int
    public var isLiked: Bool
    public var isBookmarked: Bool
    public let createdAt: Date
    public var tags: [String]?
    public var description: String { content }
    
    public init(id: UUID = UUID(), author: User, content: String, imageURLs: [URL]? = nil, videoURL: URL? = nil,
         likes: Int = 0, comments: Int = 0, shares: Int = 0, isLiked: Bool = false,
         isBookmarked: Bool = false, createdAt: Date = Date(), tags: [String]? = nil) {
        self.id = id
        self.author = author
        self.content = content
        self.imageURLs = imageURLs
        self.videoURL = videoURL
        self.likes = likes
        self.comments = comments
        self.shares = shares
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
        self.createdAt = createdAt
        self.tags = tags
    }
}

// MARK: - Feed Post Model
struct FeedPost: Identifiable, Codable, Hashable {
    public let id: String
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

// CreatePostRequest defined in APIResponseModels.swift (duplicate removed)

// MARK: - Achievement Model

struct Achievement: Identifiable, Codable, Hashable {
    public let id: UUID
    public let title: String
    public let description: String
    let iconName: String
    let dateEarned: Date
    let progress: Double?
    let isCompleted: Bool
}

// MARK: - Study Plan

struct StudyPlan: Identifiable, Hashable {
    public let id: UUID
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var courseIds: [UUID]
    var progress: Double = 0.0
    var isActive: Bool = true
}

// MARK: - Chat Typealiases (unify legacy ChatMessage with AIMessage)
// typealias ChatMessage = AIMessage

// ChatConversation moved to its own file ChatConversation.swift to prevent accidental duplicates.

// MARK: - Story

struct Story: Identifiable {
    public let id: UUID
    let author: User
    let mediaURL: String
    let mediaType: MediaType
    let duration: TimeInterval?
    let text: String?
    let createdAt: Date
    let expiresAt: Date
    let views: Int
    let imageURLs: [String]?
    let videoURL: String?
    let sharesCount: Int
    
    enum MediaType {
        case image
        case video
    }
}

// MARK: - Stubs for APIResponseModels missing types (can be expanded later)
public struct CourseOutline: Codable, Identifiable {
    public let id: String
    public let title: String
    public let sections: [CourseOutlineSection]
}
public struct CourseOutlineSection: Codable, Identifiable { public let id: String; public let title: String; public let lessonIds: [String] }

public struct ResponseChatMessage: Codable, Identifiable, Equatable {
    public let id: String
    public let content: String
    public let sender: String
    public let timestamp: String
}

// MARK: - Learning Resource

public struct LearningResource: Identifiable, Equatable, Codable {
    public let id: String
    public let title: String
    public let description: String
    let category: String?
    let difficulty: String?
    let duration: Int?
    let thumbnailUrl: String?
    let imageUrl: String?
    public let url: String?
    let provider: String?
    let providerName: String?
    let providerUrl: String?
    let enrolledCount: Int?
    let isEnrolled: Bool?
    let reviews: Int?
    let updatedAt: String?
    let createdAt: String?
    
    // Enhanced properties
    let authorCreator: String?
    let estimatedDuration: String?
    let rating: Double?
    let difficultyLevel: DifficultyLevel?
    let contentType: ContentType
    let resourcePlatform: ResourcePlatform?
    let tags: [String]?
    let isBookmarked: Bool
    let progress: Double?
    let publishedDate: Date?
    
    // Coding keys for custom date handling
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, difficulty, duration
        case thumbnailUrl, imageUrl, url, provider, providerName, providerUrl
        case enrolledCount, isEnrolled, reviews, updatedAt, createdAt
        case authorCreator, estimatedDuration, rating, difficultyLevel
        case contentType, resourcePlatform, tags, isBookmarked, progress
        case publishedDateString
    }
    
    // Custom decoder to handle Date
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        providerName = try container.decodeIfPresent(String.self, forKey: .providerName)
        providerUrl = try container.decodeIfPresent(String.self, forKey: .providerUrl)
        enrolledCount = try container.decodeIfPresent(Int.self, forKey: .enrolledCount)
        isEnrolled = try container.decodeIfPresent(Bool.self, forKey: .isEnrolled)
        reviews = try container.decodeIfPresent(Int.self, forKey: .reviews)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        authorCreator = try container.decodeIfPresent(String.self, forKey: .authorCreator)
        estimatedDuration = try container.decodeIfPresent(String.self, forKey: .estimatedDuration)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        difficultyLevel = try container.decodeIfPresent(DifficultyLevel.self, forKey: .difficultyLevel)
        contentType = try container.decode(ContentType.self, forKey: .contentType)
        resourcePlatform = try container.decodeIfPresent(ResourcePlatform.self, forKey: .resourcePlatform)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        isBookmarked = try container.decode(Bool.self, forKey: .isBookmarked)
        progress = try container.decodeIfPresent(Double.self, forKey: .progress)
        
        // Handle publishedDate from string
        if let dateString = try container.decodeIfPresent(String.self, forKey: .publishedDateString) {
            publishedDate = ISO8601DateFormatter().date(from: dateString)
        } else {
            publishedDate = nil
        }
    }
    
    // Custom encoder to handle Date
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(providerName, forKey: .providerName)
        try container.encodeIfPresent(providerUrl, forKey: .providerUrl)
        try container.encodeIfPresent(enrolledCount, forKey: .enrolledCount)
        try container.encodeIfPresent(isEnrolled, forKey: .isEnrolled)
        try container.encodeIfPresent(reviews, forKey: .reviews)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(authorCreator, forKey: .authorCreator)
        try container.encodeIfPresent(estimatedDuration, forKey: .estimatedDuration)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(difficultyLevel, forKey: .difficultyLevel)
        try container.encode(contentType, forKey: .contentType)
        try container.encodeIfPresent(resourcePlatform, forKey: .resourcePlatform)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(isBookmarked, forKey: .isBookmarked)
        try container.encodeIfPresent(progress, forKey: .progress)
        
        // Encode publishedDate as string
        if let date = publishedDate {
            try container.encode(ISO8601DateFormatter().string(from: date), forKey: .publishedDateString)
        }
    }
    
    // UI Computed properties
    var thumbnailURL: URL? {
        guard let urlString = thumbnailUrl else { return nil }
        return URL(string: urlString)
    }
    
    var contentURL: URL? {
        guard let urlString = url ?? providerUrl else { return nil }
        return URL(string: urlString)
    }
    
    // Enums
    enum DifficultyLevel: String, Codable, CaseIterable {
        case beginner
        case intermediate
        case advanced
        case expert
        
        var displayName: String {
            switch self {
            case .beginner: return "Beginner"
            case .intermediate: return "Intermediate"
            case .advanced: return "Advanced"
            case .expert: return "Expert"
            }
        }
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .blue
            case .advanced: return .orange
            case .expert: return .red
            }
        }
    }
    
    enum ContentType: String, Codable, CaseIterable {
        case article
        case video
        case course
        case book
        case podcast
        case tutorial
        case documentation
        
        var displayName: String {
            switch self {
            case .article: return "Article"
            case .video: return "Video"
            case .course: return "Course"
            case .book: return "Book"
            case .podcast: return "Podcast"
            case .tutorial: return "Tutorial"
            case .documentation: return "Documentation"
            }
        }
        
        var icon: String {
            switch self {
            case .article: return "doc.text"
            case .video: return "play.rectangle"
            case .course: return "books.vertical"
            case .book: return "book"
            case .podcast: return "mic"
            case .tutorial: return "list.bullet.rectangle"
            case .documentation: return "doc"
            }
        }
        
        var color: Color {
            switch self {
            case .article: return .blue
            case .video: return .red
            case .course: return .purple
            case .book: return .brown
            case .podcast: return .orange
            case .tutorial: return .green
            case .documentation: return .gray
            }
        }
    }
    
    enum ResourcePlatform: String, Codable, CaseIterable {
        case youtube
        case udemy
        case coursera
        case medium
        case apple
        case google
        case edx
        case lyo
        case curated
        case other
        
        var displayName: String {
            switch self {
            case .youtube: return "YouTube"
            case .udemy: return "Udemy"
            case .coursera: return "Coursera"
            case .medium: return "Medium"
            case .apple: return "Apple"
            case .google: return "Google"
            case .edx: return "edX"
            case .lyo: return "Lyo"
            case .curated: return "Curated"
            case .other: return "Other"
            }
        }
    }
    
    // Default initializer
    init(
        id: String,
        title: String,
        description: String,
        category: String? = nil,
        difficulty: String? = nil,
        duration: Int? = nil,
        thumbnailUrl: String? = nil,
        imageUrl: String? = nil,
        url: String? = nil,
        provider: String? = nil,
        providerName: String? = nil,
        providerUrl: String? = nil,
        enrolledCount: Int? = nil,
        isEnrolled: Bool? = nil,
        reviews: Int? = nil,
        updatedAt: String? = nil,
        createdAt: String? = nil,
        authorCreator: String? = nil,
        estimatedDuration: String? = nil,
        rating: Double? = nil,
        difficultyLevel: DifficultyLevel? = nil,
        contentType: ContentType = .article,
        resourcePlatform: ResourcePlatform? = nil,
        tags: [String]? = nil,
        isBookmarked: Bool = false,
        progress: Double? = nil,
        publishedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.duration = duration
        self.thumbnailUrl = thumbnailUrl
        self.imageUrl = imageUrl
        self.url = url
        self.provider = provider
        self.providerName = providerName
        self.providerUrl = providerUrl
        self.enrolledCount = enrolledCount
        self.isEnrolled = isEnrolled
        self.reviews = reviews
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.authorCreator = authorCreator
        self.estimatedDuration = estimatedDuration
        self.rating = rating
        self.difficultyLevel = difficultyLevel
        self.contentType = contentType
        self.resourcePlatform = resourcePlatform
        self.tags = tags
        self.isBookmarked = isBookmarked
        self.progress = progress
        self.publishedDate = publishedDate
    }
    
    // UUID-based initializer for convenience
    init(
        id: UUID,
        title: String,
        description: String,
        contentType: ContentType,
        sourcePlatform: ResourcePlatform,
        authorCreator: String?,
        tags: [String],
        thumbnailURL: URL,
        contentURL: URL,
        publishedAt: Date?,
        estimatedDuration: String?,
        rating: Double?,
        language: String?,
        viewCount: Int?,
        isBookmarked: Bool,
        isFavorite: Bool,
        progress: Double?,
        category: String?,
        instructor: String?,
        prerequisites: [String]?,
        learningOutcomes: [String]?,
        lastAccessedAt: Date?,
        completionCertificate: Bool,
        price: Double?,
        currency: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id.uuidString
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = nil
        self.duration = nil
        self.thumbnailUrl = thumbnailURL.absoluteString
        self.imageUrl = nil
        self.url = contentURL.absoluteString
        self.provider = nil
        self.providerName = instructor
        self.providerUrl = nil
        self.enrolledCount = viewCount
        self.isEnrolled = false
        self.reviews = nil
        self.updatedAt = ISO8601DateFormatter().string(from: updatedAt)
        self.createdAt = ISO8601DateFormatter().string(from: createdAt)
        self.authorCreator = authorCreator
        self.estimatedDuration = estimatedDuration
        self.rating = rating
        self.difficultyLevel = nil
        self.contentType = contentType
        self.resourcePlatform = sourcePlatform
        self.tags = tags
        self.isBookmarked = isBookmarked
        self.progress = progress
        self.publishedDate = publishedAt
    }
    
    // Sample data generator for UI development
    static func sampleResources() -> [LearningResource] {
        [
            LearningResource(
                id: "1",
                title: "SwiftUI Essentials",
                description: "Learn the fundamentals of SwiftUI, Apple's modern UI framework for building user interfaces across all Apple platforms.",
                category: "Programming",
                difficulty: "intermediate",
                duration: 120,
                thumbnailUrl: "https://images.unsplash.com/photo-1536714848634-df237cf3afe9?q=80&w=1470&auto=format&fit=crop",
                imageUrl: nil,
                url: "https://example.com/swiftui-essentials",
                provider: "Apple",
                providerName: "Apple Developer",
                providerUrl: "https://developer.apple.com/tutorials/swiftui",
                enrolledCount: 1250,
                isEnrolled: true,
                reviews: 428,
                updatedAt: "2023-10-15T10:00:00Z",
                createdAt: "2023-08-01T08:30:00Z",
                authorCreator: "Apple Developer Education",
                estimatedDuration: "2 hours",
                rating: 4.8,
                difficultyLevel: .intermediate,
                contentType: .tutorial,
                resourcePlatform: .apple,
                tags: ["Swift", "iOS", "SwiftUI", "Programming"],
                isBookmarked: true,
                progress: 0.35,
                publishedDate: Date().addingTimeInterval(-5184000) // 60 days ago
            ),
            
            LearningResource(
                id: "2",
                title: "Machine Learning Fundamentals",
                description: "An introduction to the core concepts of machine learning, including supervised and unsupervised learning, neural networks, and practical applications.",
                category: "Data Science",
                difficulty: "beginner",
                duration: 180,
                thumbnailUrl: "https://images.unsplash.com/photo-1522202226988-58777c7c33b5?q=80&w=1471&auto=format&fit=crop",
                imageUrl: nil,
                url: "https://example.com/ml-fundamentals",
                provider: "Coursera",
                providerName: "Stanford University",
                providerUrl: "https://www.coursera.org/learn/machine-learning",
                enrolledCount: 4375,
                isEnrolled: false,
                reviews: 952,
                updatedAt: "2023-11-01T14:20:00Z",
                createdAt: "2023-05-15T09:45:00Z",
                authorCreator: "Dr. Andrew Smith",
                estimatedDuration: "3 hours",
                rating: 4.9,
                difficultyLevel: .beginner,
                contentType: .course,
                resourcePlatform: .coursera,
                tags: ["Machine Learning", "AI", "Data Science", "Python"],
                isBookmarked: false,
                progress: nil,
                publishedDate: Date().addingTimeInterval(-7776000) // 90 days ago
            ),
            
            LearningResource(
                id: "3",
                title: "Responsive Web Design Mastery",
                description: "Master the art of responsive web design to create websites that look great on any device, from phones to desktops.",
                category: "Web Development",
                difficulty: "intermediate",
                duration: 90,
                thumbnailUrl: "https://images.unsplash.com/photo-1547658719-da2b51169166?q=80&w=1528&auto=format&fit=crop",
                imageUrl: nil,
                url: "https://example.com/responsive-web-design",
                provider: "YouTube",
                providerName: "WebDev Academy",
                providerUrl: "https://www.youtube.com/webdev",
                enrolledCount: 2875,
                isEnrolled: true,
                reviews: 513,
                updatedAt: "2023-10-28T11:15:00Z",
                createdAt: "2023-07-20T13:30:00Z",
                authorCreator: "Sarah Johnson",
                estimatedDuration: "1.5 hours",
                rating: 4.7,
                difficultyLevel: .intermediate,
                contentType: .video,
                resourcePlatform: .youtube,
                tags: ["CSS", "HTML", "Web Development", "Responsive Design"],
                isBookmarked: true,
                progress: 0.85,
                publishedDate: Date().addingTimeInterval(-3456000) // 40 days ago
            ),
            
            LearningResource(
                id: "4",
                title: "Introduction to Quantum Computing",
                description: "An accessible introduction to the fascinating world of quantum computing, explaining qubits, superposition, and quantum algorithms.",
                category: "Computer Science",
                difficulty: "advanced",
                duration: 150,
                thumbnailUrl: "https://images.unsplash.com/photo-1563841930606-67e2bce48b78?q=80&w=1374&auto=format&fit=crop",
                imageUrl: nil,
                url: "https://example.com/quantum-computing",
                provider: "edX",
                providerName: "MIT",
                providerUrl: "https://www.edx.org/learn/quantum-computing",
                enrolledCount: 1045,
                isEnrolled: false,
                reviews: 215,
                updatedAt: "2023-11-05T16:40:00Z",
                createdAt: "2023-09-10T10:20:00Z",
                authorCreator: "Prof. Richard Feynman",
                estimatedDuration: "2.5 hours",
                rating: 4.9,
                difficultyLevel: .advanced,
                contentType: .course,
                resourcePlatform: .edx,
                tags: ["Quantum Computing", "Physics", "Computer Science", "Algorithms"],
                isBookmarked: false,
                progress: nil,
                publishedDate: Date().addingTimeInterval(-2592000) // 30 days ago
            ),
            
            LearningResource(
                id: "5",
                title: "The Complete Guide to UX Research",
                description: "Learn how to conduct effective user research to inform your design decisions and create better user experiences.",
                category: "Design",
                difficulty: "beginner",
                duration: 105,
                thumbnailUrl: "https://images.unsplash.com/photo-1633419461186-7d40a38105ec?q=80&w=1470&auto=format&fit=crop",
                imageUrl: nil,
                url: "https://example.com/ux-research",
                provider: "Udemy",
                providerName: "Design Academy",
                providerUrl: "https://www.udemy.com/course/ux-research",
                enrolledCount: 3125,
                isEnrolled: true,
                reviews: 648,
                updatedAt: "2023-10-20T09:50:00Z",
                createdAt: "2023-06-15T11:25:00Z",
                authorCreator: "Emma Williams",
                estimatedDuration: "1.75 hours",
                rating: 4.6,
                difficultyLevel: .beginner,
                contentType: .course,
                resourcePlatform: .udemy,
                tags: ["UX Design", "Research", "User Testing", "Design"],
                isBookmarked: false,
                progress: 0.2,
                publishedDate: Date().addingTimeInterval(-4320000) // 50 days ago
            )
        ]
    }
}

// MARK: - SystemHealthResponse
// Removed duplicate - using canonical version from SystemHealthResponse.swift

// MARK: - AIMessage

// MARK: - AI Chat Models
// AIMessage is now defined ONCE at the top of this file (lines 11-38)
// This section intentionally left empty to avoid duplicate definitions

// MARK: - AI Quiz Models

struct AIQuizQuestion: Identifiable, Equatable, Hashable {
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

struct AIQuizOption: Identifiable, Hashable {
    public let id: UUID
    public let text: String
    public let isCorrect: Bool
}

// MARK: - SwiftData Models

@Model
final class LearningResourceSwiftDataEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    // Renamed stored property to avoid SwiftData macro reserved name clash.
    private var resourceDescriptionStorage: String
    var contentType: String
    var resourceURLString: String?
    var tags: [String]
    var difficulty: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        contentType: String,
        resourceURLString: String? = nil,
        tags: [String] = [],
        difficulty: Int = 1
    ) {
        self.id = id
        self.title = title
        self.resourceDescriptionStorage = description
        self.contentType = contentType
        self.resourceURLString = resourceURLString
        self.tags = tags
        self.difficulty = difficulty
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var resourceURL: URL? {
        guard let urlString = resourceURLString else { return nil }
        return URL(string: urlString)
    }
    // Preserve previous API while avoiding stored property name conflict
    var description: String { resourceDescriptionStorage }
}

// MARK: - SwiftData Entity Extension

extension LearningResourceSwiftDataEntity {
    func asLearningResource() -> LearningResource {
        return LearningResource(
            id: id.uuidString,
            title: title,
            description: description,
            category: nil,
            difficulty: nil,
            duration: nil,
            thumbnailUrl: nil,
            imageUrl: nil,
            url: resourceURLString,
            provider: nil,
            providerName: nil,
            providerUrl: nil,
            enrolledCount: nil,
            isEnrolled: nil,
            reviews: nil,
            updatedAt: nil,
            createdAt: ISO8601DateFormatter().string(from: createdAt),
            authorCreator: nil,
            estimatedDuration: nil,
            rating: nil,
            difficultyLevel: nil,
            contentType: LearningResource.ContentType(rawValue: contentType) ?? .article,
            resourcePlatform: nil,
            tags: tags,
            isBookmarked: false,
            progress: nil,
            publishedDate: nil
        )
    }
}

// MARK: - Additional Content Types

// Redesigned supplemental content models to align with service usage (GoogleBooksService, YouTubeEducationService, PodcastEducationService, GamificationOverlay)

enum MediaDifficulty: String, Codable, CaseIterable { case beginner, intermediate, advanced }

struct EducationalVideo: Identifiable, Codable, Equatable {
    public let id: String // using UUID().uuidString when created client side
    var title: String
    var description: String
    var thumbnailURL: String
    var videoURL: String
    var duration: TimeInterval
    var instructor: String
    var category: String
    var difficulty: MediaDifficulty
    var tags: [String]
    var rating: Double
    var viewCount: Int
    var isBookmarked: Bool
    var watchProgress: Double
    var publishedDate: Date
    var language: String
}

struct Ebook: Identifiable, Codable, Equatable {
    public let id: String // UUID string
    var title: String
    var author: String
    var description: String
    var coverImageURL: String
    var pdfURL: String
    var category: String
    var pages: Int
    var fileSize: String
    var rating: Double
    var downloadCount: Int
    var isBookmarked: Bool
    var readProgress: Double
    var publishedDate: Date?
    var language: String
    var tags: [String]
}

struct PodcastEpisode: Identifiable, Codable, Equatable {
    public let id: String // UUID string
    var title: String
    var description: String
    var audioURL: String
    var thumbnailURL: String
    var duration: TimeInterval
    var showName: String
    var publishedDate: Date
    var category: String
    var difficulty: MediaDifficulty
    var tags: [String]
    var transcript: String?
    var isBookmarked: Bool
    var playProgress: Double
}

public enum BadgeRarity: String, Codable, CaseIterable {
    case common, rare, epic, legendary

    public var color: Color {
        switch self {
        case .common:
            return .gray
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return .orange
        }
    }
}

public struct UserBadge: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var description: String
    public var iconName: String
    public var color: String
    public var rarity: BadgeRarity
    public var earnedAt: Date

    public init(id: UUID = UUID(), name: String, description: String, iconName: String, color: String, rarity: BadgeRarity, earnedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.color = color
        self.rarity = rarity
        self.earnedAt = earnedAt
    }
}

// MARK: - Legacy Typealiases (transitional - to be removed after migration)
// typealias LegacyLearningResource = LearningResource // Removed to fix ambiguous type lookup

// MARK: - Convenience extensions

extension LearningResource {
    // Backwards compatibility shim (older code referenced isDownloaded / contentURLString etc.)
    var isDownloaded: Bool { false }
    var contentURLString: String? { contentURL?.absoluteString }
}
