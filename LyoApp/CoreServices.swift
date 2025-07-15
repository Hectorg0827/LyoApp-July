import SwiftUI
import Combine

// MARK: - Persistent Storage Manager
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - User Preferences
    func saveUserPreference<T: Codable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func loadUserPreference<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - Cache Management
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    func cacheData<T: Codable>(_ data: T, filename: String) async {
        let url = cacheDirectory.appendingPathComponent("\(filename).json")
        
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: url)
        } catch {
            print("Failed to cache data: \(error)")
        }
    }
    
    func loadCachedData<T: Codable>(_ type: T.Type, filename: String) async -> T? {
        let url = cacheDirectory.appendingPathComponent("\(filename).json")
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return nil
        }
    }
    
    func clearCache() {
        let cacheFiles = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        cacheFiles?.forEach { url in
            try? fileManager.removeItem(at: url)
        }
    }
}

// MARK: - Analytics Manager
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private var events: [AnalyticsEvent] = []
    private let maxEvents = 1000
    
    private init() {}
    
    func trackEvent(_ event: AnalyticsEvent) {
        events.append(event)
        
        // Keep only recent events
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
        
        // In a real app, send to analytics service
        print("📊 Analytics: \(event.name) - \(event.parameters)")
    }
    
    func trackScreenView(_ screenName: String) {
        trackEvent(AnalyticsEvent(
            name: "screen_view",
            parameters: ["screen_name": screenName]
        ))
    }
    
    func trackUserAction(_ action: String, parameters: [String: Any] = [:]) {
        trackEvent(AnalyticsEvent(
            name: "user_action",
            parameters: ["action": action].merging(parameters) { $1 }
        ))
    }
    
    func trackLearningProgress(_ progress: LearningProgress) {
        trackEvent(AnalyticsEvent(
            name: "learning_progress",
            parameters: [
                "course_id": progress.courseId,
                "lesson_id": progress.lessonId,
                "progress_percentage": progress.percentage,
                "time_spent": progress.timeSpent
            ]
        ))
    }
}

struct AnalyticsEvent {
    let id = UUID()
    let name: String
    let parameters: [String: Any]
    let timestamp = Date()
}

struct LearningProgress: Codable {
    let courseId: String
    let lessonId: String
    let percentage: Double
    let timeSpent: TimeInterval
}

// MARK: - Notification Manager
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    
    private init() {
        checkPermission()
    }
    
    func requestPermission() async {
        do {
            hasPermission = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    private func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleNotification(
        title: String,
        body: String,
        identifier: String,
        timeInterval: TimeInterval
    ) async {
        guard hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    func scheduleReminder(for course: Course, in hours: Int) async {
        await scheduleNotification(
            title: "Time to Learn! 📚",
            body: "Continue your progress in \(course.title)",
            identifier: "course_reminder_\(course.id)",
            timeInterval: TimeInterval(hours * 3600)
        )
    }
    
    func scheduleAchievementNotification(for badge: Badge) async {
        await scheduleNotification(
            title: "Achievement Unlocked! 🏆",
            body: "You earned the \(badge.name) badge!",
            identifier: "achievement_\(badge.id)",
            timeInterval: 1
        )
    }
}

// MARK: - Error Tracking
class ErrorTracker: ObservableObject {
    static let shared = ErrorTracker()
    
    @Published var recentErrors: [TrackedAppError] = []
    
    private init() {}
    
    func trackError(_ error: Error, context: String = "") {
        let trackedError = TrackedAppError(
            originalError: error,
            context: context,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.recentErrors.insert(trackedError, at: 0)
            
            // Keep only recent 50 errors
            if self.recentErrors.count > 50 {
                self.recentErrors.removeLast()
            }
        }
        
        // In a real app, send to crash reporting service
        print("🚨 Error tracked: \(error.localizedDescription) in \(context)")
    }
}

struct TrackedAppError: Identifiable {
    let id = UUID()
    let originalError: Error
    let context: String
    let timestamp: Date
    
    var description: String {
        originalError.localizedDescription
    }
}
