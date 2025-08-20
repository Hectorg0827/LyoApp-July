import SwiftData
import Foundation

// MARK: - SwiftData Models for Offline Storage

@Model
class LearningResourceEntity {
    @Attribute(.unique) var id: String
    var title: String
    var resourceDescription: String
    var contentType: String
    var sourcePlatform: String
    var authorCreator: String?
    var tags: [String]
    var thumbnailURLString: String
    var contentURLString: String
    var publishedAt: Date?
    var difficultyLevel: String?
    var estimatedDuration: String?
    var rating: Double?
    var language: String?
    var viewCount: Int?
    var isBookmarked: Bool
    var isFavorite: Bool
    var progress: Double?
    var category: String?
    var instructor: String?
    var prerequisites: [String]?
    var learningOutcomes: [String]?
    var lastAccessedAt: Date?
    var completionCertificate: Bool
    var price: Double?
    var currency: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Local storage fields
    var isDownloaded: Bool
    var downloadDate: Date?
    var videoData: Data?
    var audioData: Data?
    var thumbnailData: Data?
    var timeSpent: TimeInterval

    // AI-enhanced metadata
    var aiSummary: String?
    var studyQuestions: [String]?
    var personalizedInsights: String?
    // Store embeddings as Double for better persistence compatibility
    var embeddings: [Double]?
    
    init(from resource: LearningResource) {
        self.id = resource.id.uuidString
        self.title = resource.title
    self.resourceDescription = resource.description
        self.contentType = resource.contentType.rawValue
        self.sourcePlatform = resource.sourcePlatform.rawValue
        self.authorCreator = resource.authorCreator
        self.tags = resource.tags
        self.thumbnailURLString = resource.thumbnailURL?.absoluteString ?? ""
        self.contentURLString = resource.contentURL?.absoluteString ?? ""
        self.publishedAt = resource.publishedAt
        self.difficultyLevel = resource.difficultyLevel?.rawValue
        self.estimatedDuration = resource.estimatedDuration
        self.rating = resource.rating
        self.language = resource.language
        self.viewCount = resource.viewCount
        self.isBookmarked = resource.isBookmarked
        self.isFavorite = resource.isFavorite
        self.progress = resource.progress
        self.category = resource.category
        self.instructor = resource.instructor
        self.prerequisites = resource.prerequisites
        self.learningOutcomes = resource.learningOutcomes
        self.lastAccessedAt = resource.lastAccessedAt
        self.completionCertificate = resource.completionCertificate
        self.price = resource.price
        self.currency = resource.currency
        self.createdAt = resource.createdAt
        self.updatedAt = resource.updatedAt
        
        // Initialize local fields
        self.isDownloaded = false
        self.timeSpent = 0
    }
    
    // Convert to LearningResource for UI
    func toLearningResource() -> LearningResource? {
        guard let uuid = UUID(uuidString: id),
              let contentType = LearningResource.ContentType(rawValue: contentType),
              let sourcePlatform = LearningResource.SourcePlatform(rawValue: sourcePlatform),
              let thumbnailURL = URL(string: thumbnailURLString),
              let contentURL = URL(string: contentURLString) else {
            return nil
        }
        
        return LearningResource(
            id: uuid,
            title: title,
            description: resourceDescription,
            contentType: contentType,
            sourcePlatform: sourcePlatform,
            authorCreator: authorCreator,
            tags: tags,
            thumbnailURL: thumbnailURL,
            contentURL: contentURL,
            publishedAt: publishedAt,
            difficultyLevel: difficultyLevel.flatMap { LearningResource.DifficultyLevel(rawValue: $0) },
            estimatedDuration: estimatedDuration,
            rating: rating,
            language: language,
            viewCount: viewCount,
            isBookmarked: isBookmarked,
            isFavorite: isFavorite,
            progress: progress,
            category: category,
            instructor: instructor,
            prerequisites: prerequisites,
            learningOutcomes: learningOutcomes,
            lastAccessedAt: lastAccessedAt,
            completionCertificate: completionCertificate,
            price: price,
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
class UserProgressEntity {
    @Attribute(.unique) var id: String
    var userId: String
    var resourceId: String
    var progress: Double // 0.0 to 1.0
    var isCompleted: Bool
    var timeSpent: TimeInterval
    var lastAccessedDate: Date
    var completedDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // Analytics data
    var sessionCount: Int
    var averageSessionTime: TimeInterval
    var streakDays: Int
    var lastStreakDate: Date?
    
    init(
        userId: String,
        resourceId: String,
        progress: Double = 0.0,
        isCompleted: Bool = false,
        timeSpent: TimeInterval = 0,
        sessionCount: Int = 0,
        averageSessionTime: TimeInterval = 0,
        streakDays: Int = 0
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.resourceId = resourceId
        self.progress = progress
        self.isCompleted = isCompleted
        self.timeSpent = timeSpent
        self.sessionCount = sessionCount
        self.averageSessionTime = averageSessionTime
        self.streakDays = streakDays
        self.lastAccessedDate = Date()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
class DownloadEntity {
    @Attribute(.unique) var id: String
    var resourceId: String
    var contentType: String // "video", "audio", "thumbnail"
    var fileName: String
    var filePath: String
    var fileSize: Int64
    var downloadDate: Date
    var isComplete: Bool
    var progress: Double // 0.0 to 1.0
    
    init(
        resourceId: String,
        contentType: String,
        fileName: String,
        filePath: String,
        fileSize: Int64 = 0,
        isComplete: Bool = false,
        progress: Double = 0.0
    ) {
        self.id = UUID().uuidString
        self.resourceId = resourceId
        self.contentType = contentType
        self.fileName = fileName
        self.filePath = filePath
        self.fileSize = fileSize
        self.isComplete = isComplete
        self.progress = progress
        self.downloadDate = Date()
    }
}

@Model
class UserEntity {
    @Attribute(.unique) var id: String
    var username: String
    var email: String
    var fullName: String?
    var profileImageURL: String?
    var profileImageData: Data?
    var isOnline: Bool
    var lastActiveDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // Learning preferences
    var preferredCategories: [String]
    var studyGoalMinutes: Int // daily goal in minutes
    var preferredDifficulty: String?
    var learningStreak: Int
    var totalStudyTime: TimeInterval
    var completedCourses: Int
    
    init(
        id: String,
        username: String,
        email: String,
        fullName: String? = nil,
        profileImageURL: String? = nil,
        isOnline: Bool = false,
        preferredCategories: [String] = [],
        studyGoalMinutes: Int = 30,
        preferredDifficulty: String? = nil,
        learningStreak: Int = 0,
        totalStudyTime: TimeInterval = 0,
        completedCourses: Int = 0
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.fullName = fullName
        self.profileImageURL = profileImageURL
        self.isOnline = isOnline
        self.preferredCategories = preferredCategories
        self.studyGoalMinutes = studyGoalMinutes
        self.preferredDifficulty = preferredDifficulty
        self.learningStreak = learningStreak
        self.totalStudyTime = totalStudyTime
        self.completedCourses = completedCourses
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to User for UI
    func toUser() -> User {
        let uuid = UUID(uuidString: id) ?? UUID()
        return User(
            id: uuid,
            username: username,
            email: email,
            fullName: fullName ?? "",
            bio: nil,
            profileImageURL: profileImageURL,
            followers: 0,
            following: 0,
            posts: 0,
            badges: [],
            level: 1,
            experience: 0,
            joinDate: createdAt
        )
    }
}
