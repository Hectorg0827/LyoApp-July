import SwiftData
import Foundation

// MARK: - Data Manager for SwiftData Operations
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private var modelContainer: ModelContainer
    private var modelContext: ModelContext
    
    init() {
        do {
            // Configure the model container
            let schema = Schema([
                LearningResourceEntity.self,
                UserProgressEntity.self,
                DownloadEntity.self,
                UserEntity.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none // Disable CloudKit for now
            )
            
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            self.modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var context: ModelContext {
        return modelContext
    }
    
    // MARK: - Learning Resources
    
    func saveLearningResource(_ resource: LearningResource) throws {
        let entity = LearningResourceEntity(from: resource)
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func saveLearningResources(_ resources: [LearningResource]) throws {
        for resource in resources {
            let entity = LearningResourceEntity(from: resource)
            modelContext.insert(entity)
        }
        try modelContext.save()
    }
    
    func fetchLearningResources() -> [LearningResource] {
        do {
            let descriptor = FetchDescriptor<LearningResourceEntity>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            let entities = try modelContext.fetch(descriptor)
            return entities.compactMap { $0.toLearningResource() }
        } catch {
            print("Failed to fetch learning resources: \(error)")
            return []
        }
    }
    
    func fetchLearningResource(by id: String) -> LearningResource? {
        do {
            let predicate = #Predicate<LearningResourceEntity> { $0.id == id }
            let descriptor = FetchDescriptor<LearningResourceEntity>(predicate: predicate)
            let entities = try modelContext.fetch(descriptor)
            return entities.first?.toLearningResource()
        } catch {
            print("Failed to fetch learning resource: \(error)")
            return nil
        }
    }
    
    func searchLearningResources(query: String) -> [LearningResource] {
        do {
            let predicate = #Predicate<LearningResourceEntity> { resource in
                resource.title.localizedCaseInsensitiveContains(query) ||
                resource.description.localizedCaseInsensitiveContains(query) ||
                (resource.category?.localizedCaseInsensitiveContains(query) ?? false)
            }
            let descriptor = FetchDescriptor<LearningResourceEntity>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.rating, order: .reverse)]
            )
            let entities = try modelContext.fetch(descriptor)
            return entities.compactMap { $0.toLearningResource() }
        } catch {
            print("Failed to search learning resources: \(error)")
            return []
        }
    }
    
    // MARK: - User Progress
    
    func saveUserProgress(_ userId: String, resourceId: String, progress: Double, timeSpent: TimeInterval, isCompleted: Bool = false) throws {
        // Check if progress already exists
        let predicate = #Predicate<UserProgressEntity> { 
            $0.userId == userId && $0.resourceId == resourceId 
        }
        let descriptor = FetchDescriptor<UserProgressEntity>(predicate: predicate)
        
        if let existingProgress = try modelContext.fetch(descriptor).first {
            // Update existing progress
            existingProgress.progress = progress
            existingProgress.timeSpent += timeSpent
            existingProgress.isCompleted = isCompleted
            existingProgress.lastAccessedDate = Date()
            existingProgress.updatedAt = Date()
            existingProgress.sessionCount += 1
            existingProgress.averageSessionTime = existingProgress.timeSpent / Double(existingProgress.sessionCount)
            
            if isCompleted && existingProgress.completedDate == nil {
                existingProgress.completedDate = Date()
            }
        } else {
            // Create new progress
            let progressEntity = UserProgressEntity(
                userId: userId,
                resourceId: resourceId,
                progress: progress,
                isCompleted: isCompleted,
                timeSpent: timeSpent,
                sessionCount: 1,
                averageSessionTime: timeSpent
            )
            
            if isCompleted {
                progressEntity.completedDate = Date()
            }
            
            modelContext.insert(progressEntity)
        }
        
        try modelContext.save()
    }
    
    func fetchUserProgress(userId: String, resourceId: String) -> UserProgressEntity? {
        do {
            let predicate = #Predicate<UserProgressEntity> { 
                $0.userId == userId && $0.resourceId == resourceId 
            }
            let descriptor = FetchDescriptor<UserProgressEntity>(predicate: predicate)
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Failed to fetch user progress: \(error)")
            return nil
        }
    }
    
    func fetchUserProgress(userId: String) -> [UserProgressEntity] {
        do {
            let predicate = #Predicate<UserProgressEntity> { $0.userId == userId }
            let descriptor = FetchDescriptor<UserProgressEntity>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.lastAccessedDate, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch user progress: \(error)")
            return []
        }
    }
    
    // MARK: - Downloads
    
    func saveDownload(resourceId: String, contentType: String, fileName: String, filePath: String, fileSize: Int64) throws {
        let download = DownloadEntity(
            resourceId: resourceId,
            contentType: contentType,
            fileName: fileName,
            filePath: filePath,
            fileSize: fileSize,
            isComplete: true,
            progress: 1.0
        )
        
        modelContext.insert(download)
        try modelContext.save()
    }
    
    func fetchDownloads(for resourceId: String) -> [DownloadEntity] {
        do {
            let predicate = #Predicate<DownloadEntity> { $0.resourceId == resourceId }
            let descriptor = FetchDescriptor<DownloadEntity>(predicate: predicate)
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch downloads: \(error)")
            return []
        }
    }
    
    func deleteDownload(_ download: DownloadEntity) throws {
        modelContext.delete(download)
        try modelContext.save()
    }
    
    // MARK: - User Data
    
    func saveUser(_ user: User) throws {
        let entity = UserEntity(
            id: user.id,
            username: user.username,
            email: user.email,
            fullName: user.fullName,
            profileImageURL: user.profileImageURL,
            isOnline: user.isOnline
        )
        
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func fetchUser(by id: String) -> User? {
        do {
            let predicate = #Predicate<UserEntity> { $0.id == id }
            let descriptor = FetchDescriptor<UserEntity>(predicate: predicate)
            let entities = try modelContext.fetch(descriptor)
            return entities.first?.toUser()
        } catch {
            print("Failed to fetch user: \(error)")
            return nil
        }
    }
    
    // MARK: - Cleanup Methods
    
    func clearCache() throws {
        // Clear all cached data
        try modelContext.delete(model: LearningResourceEntity.self)
        try modelContext.delete(model: UserProgressEntity.self)
        try modelContext.delete(model: DownloadEntity.self)
        try modelContext.save()
    }
    
    func clearUserData() throws {
        try modelContext.delete(model: UserEntity.self)
        try modelContext.delete(model: UserProgressEntity.self)
        try modelContext.save()
    }
}
