import Foundation

/// Simple analytics stub for production app
class Analytics {
    static let shared = Analytics()
    
    private init() {}
    
    // MARK: - Tracking Methods
    func track(_ event: String) {
        print("📊 Analytics: \(event)")
    }
    
    func track(_ event: String, properties: [String: Any]) {
        print("📊 Analytics: \(event) - \(properties)")
    }
    
    func trackScreenView(_ screenName: String) {
        print("📊 Screen View: \(screenName)")
    }
    
    func trackSessionStart() {
        print("📊 Session started")
    }
    
    func trackSessionEnd() {
        print("📊 Session ended")
    }
    
    func setUserId(_ userId: String) {
        print("📊 User ID set: \(userId)")
    }
}

// MARK: - Analytics Event Types
enum AnalyticsEvent {
    case userAction(String)
    case screenView(String)
    case courseInteraction(String)
    case learningProgress(String, Double)
    
    var name: String {
        switch self {
        case .userAction(let action):
            return "user_action_\(action)"
        case .screenView(let screen):
            return "screen_view_\(screen)"
        case .courseInteraction(let course):
            return "course_\(course)"
        case .learningProgress(let courseId, _):
            return "learning_progress_\(courseId)"
        }
    }
}
