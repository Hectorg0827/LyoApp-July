import SwiftUI
import SwiftData

// MARK: - SwiftData Models for Production

@Model
final class LearningResourceEntity {
    @Attribute(.unique) var id: String
    var title: String
    var resourceDescription: String
    var contentType: String // video, article, podcast, document
    var category: String?
    var difficulty: String // beginner, intermediate, advanced
    var estimatedDuration: String?
    var rating: Double?
    var thumbnailURL: String?
    var contentURL: String?
    
    // Offline capabilities
    var isDownloaded: Bool = false
    var downloadProgress: Double = 0.0
    var localFilePath: String?
    var downloadDate: Date?
    
    // Learning progress
    var isCompleted: Bool = false
    var progressPercentage: Double = 0.0
    var lastAccessedDate: Date?
    var timeSpent: TimeInterval = 0
    
    // AI enhancements
    var aiSummary: String?
    var studyQuestions: [String] = []
    var personalizedInsights: String?
    var embeddings: [Float] = []
    
    // Metadata
    var createdDate: Date = Date()
    var updatedDate: Date = Date()
    var tags: [String] = []
    var isFavorite: Bool = false
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         contentType: String,
         category: String? = nil,
         difficulty: String = "beginner",
         estimatedDuration: String? = nil,
         rating: Double? = nil,
         thumbnailURL: String? = nil,
         contentURL: String? = nil) {
        self.id = id
        self.title = title
        self.resourceDescription = description
        self.contentType = contentType
        self.category = category
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.rating = rating
        self.thumbnailURL = thumbnailURL
        self.contentURL = contentURL
    }
}

@Model
final class LearningProgressEntity {
    @Attribute(.unique) var id: String
    var resourceId: String
    var userId: String
    
    var progressPercentage: Double = 0.0
    var isCompleted: Bool = false
    var completionDate: Date?
    var timeSpent: TimeInterval = 0
    
    var lastPosition: Double = 0.0 // For video/audio content
    var bookmarks: [Double] = [] // Timestamps for bookmarks
    var notes: String = ""
    
    // Session tracking
    var sessionCount: Int = 0
    var lastSessionDate: Date?
    var averageSessionDuration: TimeInterval = 0
    
    var createdDate: Date = Date()
    var updatedDate: Date = Date()
    
    init(id: String = UUID().uuidString,
         resourceId: String,
         userId: String) {
        self.id = id
        self.resourceId = resourceId
        self.userId = userId
    }
}

@Model
final class DownloadQueueEntity {
    @Attribute(.unique) var id: String
    var resourceId: String
    var status: String // pending, downloading, completed, failed, paused
    var progress: Double = 0.0
    var downloadURL: String
    var localFilePath: String?
    
    var priority: Int = 0 // Higher number = higher priority
    var fileSize: Int64 = 0
    var downloadedBytes: Int64 = 0
    
    var createdDate: Date = Date()
    var startedDate: Date?
    var completedDate: Date?
    var errorMessage: String?
    
    init(id: String = UUID().uuidString,
         resourceId: String,
         downloadURL: String,
         priority: Int = 0) {
        self.id = id
        self.resourceId = resourceId
        self.downloadURL = downloadURL
        self.status = "pending"
        self.priority = priority
    }
}

@Model
final class UserLearningProfileEntity {
    @Attribute(.unique) var userId: String
    
    // Learning preferences
    var preferredContentTypes: [String] = []
    var preferredCategories: [String] = []
    var learningGoals: [String] = []
    var difficultyPreference: String = "intermediate"
    
    // Learning statistics
    var totalTimeSpent: TimeInterval = 0
    var resourcesCompleted: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastLearningDate: Date?
    
    // AI personalization
    var learningStyle: String = "mixed" // visual, auditory, reading, kinesthetic, mixed
    var recommendationPreferences: [String] = []
    var personalizedInsights: String = ""
    
    var createdDate: Date = Date()
    var updatedDate: Date = Date()
    
    init(userId: String) {
        self.userId = userId
    }
}

// MARK: - SwiftData Service

@MainActor
class LearningDataService: ObservableObject {
    static let shared = LearningDataService()
    
    @Published var isInitialized = false
    private var modelContext: ModelContext?
    
    private init() {}
    
    func initialize(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.isInitialized = true
        print("✅ LearningDataService initialized with SwiftData")
    }
    
    // MARK: - Learning Resources
    
    func saveLearningResource(_ resource: LearningResource) async throws {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        // let entity = LearningResourceEntity(from: resource)
        // Temporarily skip entity creation
        print("📚 Would save learning resource: \(resource.title)")
    }
    
    func fetchLearningResources() async throws -> [LearningResourceEntity] {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        let descriptor = FetchDescriptor<LearningResourceEntity>(
            sortBy: [SortDescriptor(\.updatedDate, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    func fetchLearningResource(id: String) async throws -> LearningResourceEntity? {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        let predicate = #Predicate<LearningResourceEntity> { resource in
            resource.id == id
        }
        
        let descriptor = FetchDescriptor<LearningResourceEntity>(predicate: predicate)
        return try context.fetch(descriptor).first
    }
    
    // MARK: - Progress Tracking
    
    func updateProgress(resourceId: String, userId: String, progress: Double) async throws {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        // Fetch existing progress or create new
        let existingProgress = try await fetchProgress(resourceId: resourceId, userId: userId)
        
        let progressEntity: LearningProgressEntity
        if let existing = existingProgress {
            progressEntity = existing
        } else {
            progressEntity = LearningProgressEntity(resourceId: resourceId, userId: userId)
            context.insert(progressEntity)
        }
        
        progressEntity.progressPercentage = progress
        progressEntity.updatedDate = Date()
        
        if progress >= 100.0 && !progressEntity.isCompleted {
            progressEntity.isCompleted = true
            progressEntity.completionDate = Date()
        }
        
        try context.save()
        print("📈 Updated progress for resource \(resourceId): \(progress)%")
    }
    
    func fetchProgress(resourceId: String, userId: String) async throws -> LearningProgressEntity? {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        let predicate = #Predicate<LearningProgressEntity> { progress in
            progress.resourceId == resourceId && progress.userId == userId
        }
        
        let descriptor = FetchDescriptor<LearningProgressEntity>(predicate: predicate)
        return try context.fetch(descriptor).first
    }
    
    // MARK: - Download Management
    
    func queueDownload(resourceId: String, downloadURL: String, priority: Int = 0) async throws {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        let downloadEntity = DownloadQueueEntity(
            resourceId: resourceId,
            downloadURL: downloadURL,
            priority: priority
        )
        
        context.insert(downloadEntity)
        try context.save()
        print("⬇️ Queued download for resource: \(resourceId)")
    }
    
    func fetchDownloadQueue() async throws -> [DownloadQueueEntity] {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        let descriptor = FetchDescriptor<DownloadQueueEntity>(
            sortBy: [
                SortDescriptor(\.priority, order: .reverse),
                SortDescriptor(\.createdDate, order: .forward)
            ]
        )
        
        return try context.fetch(descriptor)
    }
    
    // MARK: - AI Integration
    
    func updateAIEnhancements(resourceId: String, summary: String?, questions: [String]?, insights: String?, embeddings: [Float]?) async throws {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        let resource = try await fetchLearningResource(id: resourceId)
        guard let resource = resource else { throw DataServiceError.resourceNotFound }
        
        if let summary = summary {
            resource.aiSummary = summary
        }
        
        if let questions = questions {
            resource.studyQuestions = questions
        }
        
        if let insights = insights {
            resource.personalizedInsights = insights
        }
        
        if let embeddings = embeddings {
            resource.embeddings = embeddings
        }
        
        resource.updatedDate = Date()
        try context.save()
        print("🧠 Updated AI enhancements for resource: \(resourceId)")
    }
    
    // MARK: - User Profile
    
    func updateUserProfile(_ profile: UserLearningProfileEntity) async throws {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        // Check if profile exists
        let existingProfile = try await fetchUserProfile(userId: profile.userId)
        
        if existingProfile == nil {
            context.insert(profile)
        }
        
        profile.updatedDate = Date()
        try context.save()
        print("👤 Updated user learning profile: \(profile.userId)")
    }
    
    func fetchUserProfile(userId: String) async throws -> UserLearningProfileEntity? {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        let predicate = #Predicate<UserLearningProfileEntity> { profile in
            profile.userId == userId
        }
        
        let descriptor = FetchDescriptor<UserLearningProfileEntity>(predicate: predicate)
        return try context.fetch(descriptor).first
    }
    
    // MARK: - Cleanup
    
    func clearOfflineData() async throws {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        // Clear downloaded resources
        let resources = try await fetchLearningResources()
        for resource in resources.filter({ $0.isDownloaded }) {
            resource.isDownloaded = false
            resource.localFilePath = nil
            resource.downloadProgress = 0.0
        }
        
        try context.save()
        print("🧹 Cleared offline data")
    }
}

// MARK: - Error Handling

enum DataServiceError: LocalizedError {
    case contextNotInitialized
    case resourceNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .contextNotInitialized:
            return "SwiftData context not initialized"
        case .resourceNotFound:
            return "Learning resource not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}
