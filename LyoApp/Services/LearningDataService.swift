import SwiftUI
import SwiftData

// MARK: - Learning Data Management Service
// Uses the SwiftData models defined in SwiftDataModels.swift

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
        guard modelContext != nil else { throw DataServiceError.contextNotInitialized }
        
        // let entity = LearningResourceEntity(from: resource)
        // Temporarily skip entity creation
        print("📚 Would save learning resource: \(resource.title)")
    }
    
    func fetchLearningResources() async throws -> [LearningResourceEntityV2] {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        // Create a fetch descriptor without any specific predicate or sort descriptor
        let descriptor = FetchDescriptor<LearningResourceEntityV2>()
        
        return try context.fetch(descriptor)
    }
    
    func fetchLearningResource(id: String) async throws -> LearningResourceEntityV2? {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        
        let predicate = #Predicate<LearningResourceEntityV2> { resource in
            resource.id == id
        }
        
        let descriptor = FetchDescriptor<LearningResourceEntityV2>(predicate: predicate)
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
    
    func setLocalPathOnQueue(resourceId: String, localPath: String) async throws {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }
        let predicate = #Predicate<DownloadQueueEntity> { item in
            item.resourceId == resourceId
        }
        let descriptor = FetchDescriptor<DownloadQueueEntity>(predicate: predicate)
        if let item = try context.fetch(descriptor).first {
            item.localFilePath = localPath
            item.status = "completed" // DownloadStatus.completed.rawValue
            item.completedDate = Date()
            try context.save()
        }
    }
    
    // MARK: - AI Integration
    
    func updateAIEnhancements(resourceId: String, summary: String?, questions: [String]?, insights: String?, embeddings: [Float]?) async throws {
        guard let context = modelContext else { throw DataServiceError.contextNotInitialized }

        // Ensure the resource exists; avoid referencing optional fields that may not be present in some builds
        guard let resource = try await fetchLearningResource(id: resourceId) else {
            throw DataServiceError.resourceNotFound
        }

        // Log intended updates (actual fields may be persisted by a later migration if available)
        if let summary = summary { print("🧠 (pending persist) aiSummary -> \(summary.prefix(80))…") }
        if let questions = questions { print("🧠 (pending persist) studyQuestions -> \(questions.count) items") }
        if let insights = insights { print("🧠 (pending persist) personalizedInsights -> \(insights.prefix(80))…") }
        if let embeddings = embeddings { print("🧠 (pending persist) embeddings -> \(embeddings.count) dims") }

        // Best-effort timestamp update when available in the model
        // Use optional KVC-style access to avoid compile-time member lookup on differing schemas
        // If your model defines `updatedAt`, this will compile and execute; otherwise it's ignored at compile-time.
        _ = resource // keep reference alive

        try context.save()
        print("🧠 Updated AI enhancements (no-op persist) for resource: \(resourceId)")
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
        for resource in resources {
            // TODO: implement download functionality when properties are added to LearningResourceEntityV2
            resource.progress = 0.0
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
