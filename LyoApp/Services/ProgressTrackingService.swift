import Foundation
import SwiftUI

// MARK: - Progress Tracking Service
/// Real-time progress tracking with backend synchronization

@MainActor
final class ProgressTrackingService: ObservableObject {
    static let shared = ProgressTrackingService()
    
    @Published var currentProgress: CourseProgress?
    @Published var isSyncing = false
    @Published var syncError: String?
    
    // Local cache for offline support
    @Published var localProgress: [UUID: CourseProgress] = [:] // courseId -> progress
    
    private let apiService = ClassroomAPIService.shared
    private let syncInterval: TimeInterval = 30 // Sync every 30 seconds
    private var syncTimer: Timer?
    
    private init() {
        loadLocalProgress()
        startAutoSync()
    }
    
    deinit {
        stopAutoSync()
    }
    
    // MARK: - Progress Management
    
    /// Mark a lesson as completed and sync to backend
    func completeLesson(
        lessonId: UUID,
        courseId: UUID,
        timeSpent: TimeInterval,
        score: Double? = nil,
        quizScore: Double? = nil
    ) async {
        print("📝 [ProgressTracking] Marking lesson \(lessonId) as complete")
        
        // Update local progress first (optimistic update)
        updateLocalProgress(
            courseId: courseId,
            lessonId: lessonId,
            isCompleted: true,
            timeSpent: timeSpent,
            score: score,
            quizScore: quizScore
        )
        
        // Sync to backend
        await syncProgressToBackend(courseId: courseId)
    }
    
    /// Update progress for current lesson chunk
    func updateLessonProgress(
        lessonId: UUID,
        courseId: UUID,
        chunkIndex: Int,
        totalChunks: Int,
        timeSpent: TimeInterval
    ) async {
        let progress = Double(chunkIndex) / Double(totalChunks)
        
        print("📊 [ProgressTracking] Lesson progress: \(Int(progress * 100))%")
        
        // Update local cache
        updateLocalProgress(
            courseId: courseId,
            lessonId: lessonId,
            isCompleted: false,
            timeSpent: timeSpent,
            chunkProgress: progress
        )
        
        // Auto-sync will handle backend update
    }
    
    /// Fetch progress from backend
    func fetchProgress(courseId: UUID, forceRefresh: Bool = false) async throws -> CourseProgress {
        // Check local cache first (unless force refresh)
        if !forceRefresh, let cached = localProgress[courseId] {
            print("📦 [ProgressTracking] Using cached progress")
            currentProgress = cached
            return cached
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            print("🔄 [ProgressTracking] Fetching progress from backend...")
            
            let progress = try await apiService.fetchProgress(courseId: courseId)
            
            // Update local cache
            localProgress[courseId] = progress
            currentProgress = progress
            saveLocalProgress()
            
            isSyncing = false
            print("✅ [ProgressTracking] Progress fetched and cached")
            
            return progress
            
        } catch {
            isSyncing = false
            syncError = error.localizedDescription
            print("❌ [ProgressTracking] Failed to fetch progress: \(error.localizedDescription)")
            
            // Return cached data if available
            if let cached = localProgress[courseId] {
                print("⚠️ [ProgressTracking] Using stale cached data")
                return cached
            }
            
            throw error
        }
    }
    
    /// Sync all local progress to backend
    func syncAllProgress() async {
        for (courseId, _) in localProgress {
            await syncProgressToBackend(courseId: courseId)
        }
    }
    
    /// Clear local cache and force refresh from backend
    func clearCache() {
        localProgress.removeAll()
        currentProgress = nil
        saveLocalProgress()
        print("🗑️ [ProgressTracking] Cache cleared")
    }
    
    // MARK: - Statistics & Analytics
    
    /// Get completion statistics for a course
    func getCompletionStats(courseId: UUID) -> CompletionStats? {
        guard let progress = localProgress[courseId] else { return nil }
        
        let completedLessons = progress.completedLessons.count
        let totalLessons = progress.totalLessons
        let completionRate = Double(completedLessons) / Double(totalLessons)
        
        let totalTimeSpent = progress.lessonProgress.values.reduce(0.0) { $0 + $1.timeSpent }
        let averageScore = progress.lessonProgress.values.compactMap { $0.score }.reduce(0.0, +) / Double(progress.lessonProgress.count)
        
        return CompletionStats(
            completedLessons: completedLessons,
            totalLessons: totalLessons,
            completionRate: completionRate,
            totalTimeSpent: totalTimeSpent,
            averageScore: averageScore,
            lastUpdated: progress.lastUpdated
        )
    }
    
    /// Get lesson-specific progress
    func getLessonProgress(lessonId: UUID, courseId: UUID) -> LessonProgress? {
        guard let courseProgress = localProgress[courseId] else { return nil }
        return courseProgress.lessonProgress[lessonId]
    }
    
    // MARK: - Private Methods
    
    private func updateLocalProgress(
        courseId: UUID,
        lessonId: UUID,
        isCompleted: Bool,
        timeSpent: TimeInterval,
        score: Double? = nil,
        quizScore: Double? = nil,
        chunkProgress: Double? = nil
    ) {
        // Get or create course progress
        var courseProgress = localProgress[courseId] ?? CourseProgress(
            id: UUID(),
            courseId: courseId,
            overallProgress: 0.0,
            completedLessons: [],
            totalLessons: 0,
            lessonProgress: [:],
            lastUpdated: Date()
        )
        
        // Get or create lesson progress
        var lessonProgress = courseProgress.lessonProgress[lessonId] ?? LessonProgress(
            lessonId: lessonId,
            isCompleted: false,
            progress: 0.0,
            timeSpent: 0,
            lastAccessedAt: Date()
        )
        
        // Update lesson progress
        lessonProgress.isCompleted = isCompleted
        lessonProgress.timeSpent += timeSpent
        lessonProgress.lastAccessedAt = Date()
        
        if let progress = chunkProgress {
            lessonProgress.progress = progress
        }
        
        if let score = score {
            lessonProgress.score = score
        }
        
        if let quizScore = quizScore {
            lessonProgress.quizScore = quizScore
        }
        
        // Update course progress
        courseProgress.lessonProgress[lessonId] = lessonProgress
        
        if isCompleted && !courseProgress.completedLessons.contains(lessonId) {
            courseProgress.completedLessons.append(lessonId)
        }
        
        // Recalculate overall progress
        let completedCount = courseProgress.completedLessons.count
        let totalCount = max(courseProgress.totalLessons, completedCount)
        courseProgress.overallProgress = Double(completedCount) / Double(totalCount)
        courseProgress.lastUpdated = Date()
        
        // Save to cache
        localProgress[courseId] = courseProgress
        currentProgress = courseProgress
        
        // Persist to disk
        saveLocalProgress()
    }
    
    private func syncProgressToBackend(courseId: UUID) async {
        guard let progress = localProgress[courseId] else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            print("🔄 [ProgressTracking] Syncing progress to backend...")
            
            try await apiService.saveProgress(progress: progress)
            
            isSyncing = false
            print("✅ [ProgressTracking] Progress synced successfully")
            
        } catch {
            isSyncing = false
            syncError = error.localizedDescription
            print("⚠️ [ProgressTracking] Sync failed: \(error.localizedDescription)")
            // Will retry on next sync interval
        }
    }
    
    // MARK: - Auto-Sync
    
    private func startAutoSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncAllProgress()
            }
        }
        print("⏰ [ProgressTracking] Auto-sync started (every \(Int(syncInterval))s)")
    }
    
    private func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        print("⏰ [ProgressTracking] Auto-sync stopped")
    }
    
    // MARK: - Persistence
    
    private func loadLocalProgress() {
        guard let data = UserDefaults.standard.data(forKey: "localCourseProgress") else {
            print("📦 [ProgressTracking] No cached progress found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            localProgress = try decoder.decode([UUID: CourseProgress].self, from: data)
            print("✅ [ProgressTracking] Loaded \(localProgress.count) cached progress entries")
        } catch {
            print("⚠️ [ProgressTracking] Failed to load cached progress: \(error)")
        }
    }
    
    private func saveLocalProgress() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(localProgress)
            UserDefaults.standard.set(data, forKey: "localCourseProgress")
            print("💾 [ProgressTracking] Progress saved to disk")
        } catch {
            print("⚠️ [ProgressTracking] Failed to save progress: \(error)")
        }
    }
}

// MARK: - Supporting Models

struct CompletionStats {
    let completedLessons: Int
    let totalLessons: Int
    let completionRate: Double
    let totalTimeSpent: TimeInterval
    let averageScore: Double
    let lastUpdated: Date
    
    var completionPercentage: Int {
        Int(completionRate * 100)
    }
    
    var timeSpentFormatted: String {
        let hours = Int(totalTimeSpent) / 3600
        let minutes = (Int(totalTimeSpent) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var averageScoreFormatted: String {
        if averageScore.isNaN || averageScore == 0 {
            return "N/A"
        }
        return String(format: "%.0f%%", averageScore * 100)
    }
}

// MARK: - CourseProgress Extension

extension CourseProgress {
    var progressPercentage: Int {
        Int(overallProgress * 100)
    }
    
    var progressDescription: String {
        "\(completedLessons.count) of \(totalLessons) lessons completed"
    }
    
    func isLessonCompleted(_ lessonId: UUID) -> Bool {
        completedLessons.contains(lessonId)
    }
}

// MARK: - LessonProgress Extension

extension LessonProgress {
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var timeSpentFormatted: String {
        let minutes = Int(timeSpent) / 60
        let seconds = Int(timeSpent) % 60
        return "\(minutes)m \(seconds)s"
    }
    
    var scoreFormatted: String {
        guard let score = score else { return "N/A" }
        return String(format: "%.0f%%", score * 100)
    }
}
