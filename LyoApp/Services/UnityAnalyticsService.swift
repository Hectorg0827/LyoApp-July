import Foundation
import Combine

// MARK: - Unity Analytics Service
/// Tracks Unity classroom interactions and learning metrics
@MainActor
class UnityAnalyticsService: ObservableObject {
    static let shared = UnityAnalyticsService()
    
    @Published var sessionMetrics: UnitySessionMetrics?
    @Published var classroomSessions: [UnityClassroomSession] = []
    
    private var currentSession: UnityClassroomSession?
    private let maxStoredSessions = 50
    
    // MARK: - Session Management
    
    func startClassroomSession(
        courseId: String,
        courseName: String,
        environment: String,
        difficulty: String
    ) {
        let session = UnityClassroomSession(
            id: UUID(),
            courseId: courseId,
            courseName: courseName,
            environment: environment,
            difficulty: difficulty,
            startTime: Date()
        )
        
        currentSession = session
        
        print("📊 [UnityAnalytics] Session started:")
        print("   Course: \(courseName)")
        print("   Environment: \(environment)")
        print("   Difficulty: \(difficulty)")
        
        // Track with app analytics
        LearningHubAnalytics.shared.trackCustomEvent(
            "unity_classroom_started",
            properties: [
                "course_id": courseId,
                "environment": environment,
                "difficulty": difficulty
            ]
        )
    }
    
    func endClassroomSession(
        completed: Bool = false,
        finalProgress: Double = 0.0,
        xpEarned: Int = 0
    ) {
        guard var session = currentSession else {
            print("⚠️ [UnityAnalytics] No active session to end")
            return
        }
        
        session.endTime = Date()
        session.completed = completed
        session.finalProgress = finalProgress
        session.xpEarned = xpEarned
        session.duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
        
        // Store session
        classroomSessions.insert(session, at: 0)
        
        // Limit stored sessions
        if classroomSessions.count > maxStoredSessions {
            classroomSessions = Array(classroomSessions.prefix(maxStoredSessions))
        }
        
        print("📊 [UnityAnalytics] Session ended:")
        print("   Duration: \(Int(session.duration))s")
        print("   Completed: \(completed)")
        print("   Progress: \(Int(finalProgress * 100))%")
        print("   XP Earned: \(xpEarned)")
        
        // Track with app analytics
        LearningHubAnalytics.shared.trackCustomEvent(
            "unity_classroom_ended",
            properties: [
                "course_id": session.courseId,
                "duration_seconds": Int(session.duration),
                "completed": completed,
                "progress": Int(finalProgress * 100),
                "xp_earned": xpEarned,
                "environment": session.environment
            ]
        )
        
        currentSession = nil
        
        // Save to persistent storage
        saveSessionsToStorage()
    }
    
    // MARK: - Interaction Tracking
    
    func trackInteraction(
        type: UnityInteractionType,
        objectName: String? = nil,
        value: String? = nil
    ) {
        guard var session = currentSession else { return }
        
        let interaction = UnityInteraction(
            type: type,
            timestamp: Date(),
            objectName: objectName,
            value: value
        )
        
        session.interactions.append(interaction)
        currentSession = session
        
        print("👆 [UnityAnalytics] Interaction: \(type.rawValue) - \(objectName ?? "N/A")")
        
        // Track significant interactions
        if type == .lessonCompleted || type == .quizPassed || type == .achievementUnlocked {
            LearningHubAnalytics.shared.trackCustomEvent(
                "unity_interaction",
                properties: [
                    "type": type.rawValue,
                    "object": objectName ?? "unknown",
                    "value": value ?? ""
                ]
            )
        }
    }
    
    func updateProgress(_ progress: Double) {
        guard var session = currentSession else { return }
        session.finalProgress = progress
        currentSession = session
    }
    
    func addXP(_ amount: Int) {
        guard var session = currentSession else { return }
        session.xpEarned += amount
        currentSession = session
        
        print("⭐ [UnityAnalytics] XP earned: +\(amount) (Total: \(session.xpEarned))")
    }
    
    // MARK: - Metrics & Analytics
    
    func calculateSessionMetrics() -> UnitySessionMetrics {
        let totalSessions = classroomSessions.count
        let completedSessions = classroomSessions.filter { $0.completed }.count
        let totalDuration = classroomSessions.reduce(0.0) { $0 + $1.duration }
        let averageDuration = totalSessions > 0 ? totalDuration / Double(totalSessions) : 0
        let totalXP = classroomSessions.reduce(0) { $0 + $1.xpEarned }
        let averageProgress = totalSessions > 0 ?
            classroomSessions.reduce(0.0) { $0 + $1.finalProgress } / Double(totalSessions) : 0
        
        let environmentCounts = Dictionary(grouping: classroomSessions, by: { $0.environment })
            .mapValues { $0.count }
        let mostUsedEnvironment = environmentCounts.max(by: { $0.value < $1.value })?.key ?? "None"
        
        return UnitySessionMetrics(
            totalSessions: totalSessions,
            completedSessions: completedSessions,
            totalDuration: totalDuration,
            averageDuration: averageDuration,
            totalXPEarned: totalXP,
            averageProgress: averageProgress,
            mostUsedEnvironment: mostUsedEnvironment
        )
    }
    
    // MARK: - Persistence
    
    private func saveSessionsToStorage() {
        // TODO: Implement UserDefaults or Core Data persistence
        // For now, keeping in memory only
    }
    
    private func loadSessionsFromStorage() {
        // TODO: Load from UserDefaults or Core Data
    }
}

// MARK: - Data Models

struct UnityClassroomSession: Identifiable {
    let id: UUID
    let courseId: String
    let courseName: String
    let environment: String
    let difficulty: String
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval = 0
    var completed: Bool = false
    var finalProgress: Double = 0.0
    var xpEarned: Int = 0
    var interactions: [UnityInteraction] = []
}

struct UnityInteraction {
    let type: UnityInteractionType
    let timestamp: Date
    let objectName: String?
    let value: String?
}

enum UnityInteractionType: String {
    case objectClicked = "object_clicked"
    case lessonStarted = "lesson_started"
    case lessonCompleted = "lesson_completed"
    case quizStarted = "quiz_started"
    case quizPassed = "quiz_passed"
    case quizFailed = "quiz_failed"
    case environmentChanged = "environment_changed"
    case tutorInteraction = "tutor_interaction"
    case achievementUnlocked = "achievement_unlocked"
    case hintRequested = "hint_requested"
}

struct UnitySessionMetrics {
    let totalSessions: Int
    let completedSessions: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let totalXPEarned: Int
    let averageProgress: Double
    let mostUsedEnvironment: String
    
    var completionRate: Double {
        totalSessions > 0 ? Double(completedSessions) / Double(totalSessions) : 0
    }
    
    var averageDurationFormatted: String {
        let minutes = Int(averageDuration) / 60
        let seconds = Int(averageDuration) % 60
        return "\(minutes)m \(seconds)s"
    }
}

// MARK: - Unity Error Handling
enum UnityIntegrationError: LocalizedError {
    case frameworkNotLoaded
    case initializationFailed(String)
    case viewCreationFailed
    case messageDeliveryFailed(String)
    case invalidJSON
    case environmentNotFound(String)
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .frameworkNotLoaded:
            return "Unity framework is not loaded. Please ensure UnityFramework.framework is embedded in the app."
        case .initializationFailed(let reason):
            return "Unity initialization failed: \(reason)"
        case .viewCreationFailed:
            return "Failed to create Unity view. The framework may not be initialized."
        case .messageDeliveryFailed(let message):
            return "Failed to deliver message to Unity: \(message)"
        case .invalidJSON:
            return "Invalid JSON format for Unity course data."
        case .environmentNotFound(let env):
            return "Unity environment '\(env)' not found. Check if the scene is included in the Unity build."
        case .configurationError(let details):
            return "Unity configuration error: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .frameworkNotLoaded:
            return "Rebuild the Unity project as a library and re-embed the framework."
        case .initializationFailed:
            return "Check Unity logs and ensure the framework is properly configured."
        case .viewCreationFailed:
            return "Try restarting the app or reinitializing Unity."
        case .messageDeliveryFailed:
            return "Ensure the ClassroomController GameObject exists in the Unity scene."
        case .invalidJSON:
            return "Verify the LearningResource data is complete and valid."
        case .environmentNotFound:
            return "Add the missing environment scene to the Unity project and rebuild."
        case .configurationError:
            return "Check Unity integration settings and configuration files."
        }
    }
}
