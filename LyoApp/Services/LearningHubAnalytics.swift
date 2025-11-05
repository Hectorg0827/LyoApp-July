import Foundation
// import FirebaseAnalytics // TEMPORARY: Commented until Xcode resolves packages properly

/// Learning Hub Analytics Service - Track user interactions and learning behavior
@MainActor
class LearningHubAnalytics: ObservableObject {
    static let shared = LearningHubAnalytics()
    
    private init() {}
    
    // MARK: - Stub Analytics (temporary until Firebase resolves)
    private func logEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        #if DEBUG
        print("📊 Analytics: \(eventName)")
        if let params = parameters {
            print("   Params: \(params)")
        }
        #endif
    }
    
    // MARK: - Conversation Analytics
    
    /// Track when user starts a conversation
    func trackConversationStarted() {
        logEvent("conversation_started", parameters: [
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Conversation started")
    }
    
    /// Track user message in conversation
    func trackUserMessage(content: String, conversationState: String) {
        logEvent("user_message", parameters: [
            "content_length": content.count,
            "conversation_state": conversationState,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: User message - state: \(conversationState)")
    }
    
    /// Track AI response
    func trackAIResponse(responseType: String, conversationState: String) {
        logEvent("ai_response", parameters: [
            "response_type": responseType,
            "conversation_state": conversationState,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: AI response - type: \(responseType)")
    }
    
    /// Track quick action selection
    func trackQuickActionSelected(actionTitle: String, actionValue: String) {
        logEvent("quick_action_selected", parameters: [
            "action_title": actionTitle,
            "action_value": actionValue,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Quick action - \(actionTitle)")
    }
    
    // MARK: - Course Generation Analytics
    
    /// Track course generation initiated
    func trackCourseGenerationStarted(topic: String, level: String, focus: String?) {
        logEvent("course_generation_started", parameters: [
            "topic": topic,
            "level": level,
            "focus": focus ?? "general",
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Course generation started - \(topic) (\(level))")
    }
    
    /// Track course generation completed
    func trackCourseGenerationCompleted(
        topic: String,
        level: String,
        moduleCount: Int,
        duration: String,
        xpReward: Int,
        usedBackend: Bool
    ) {
        logEvent("course_generation_completed", parameters: [
            "topic": topic,
            "level": level,
            "module_count": moduleCount,
            "duration": duration,
            "xp_reward": xpReward,
            "used_backend": usedBackend,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Course generated - \(topic) with \(moduleCount) modules")
    }
    
    /// Track course generation failed
    func trackCourseGenerationFailed(topic: String, level: String, error: String) {
        logEvent("course_generation_failed", parameters: [
            "topic": topic,
            "level": level,
            "error": error,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Course generation failed - \(error)")
    }
    
    // MARK: - Course Launch Analytics
    
    /// Track countdown started
    func trackCountdownStarted(courseTitle: String) {
        logEvent("course_launch_countdown", parameters: [
            "course_title": courseTitle,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Launch countdown - \(courseTitle)")
    }
    
    /// Track course launched
    func trackCourseLaunched(
        courseTitle: String,
        topic: String,
        level: String,
        environment: String,
        timeToLaunch: Double
    ) {
        logEvent("course_launched", parameters: [
            "course_title": courseTitle,
            "topic": topic,
            "level": level,
            "environment": environment,
            "time_to_launch": timeToLaunch,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Course launched - \(courseTitle) in \(environment)")
    }
    
    // MARK: - User Interaction Analytics
    
    /// Track voice input used
    func trackVoiceInputUsed(duration: Double, transcribedLength: Int) {
        logEvent("voice_input_used", parameters: [
            "duration": duration,
            "transcribed_length": transcribedLength,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Voice input - \(duration)s, \(transcribedLength) chars")
    }
    
    /// Track course card interaction
    func trackCourseCardInteraction(courseId: String, courseTitle: String, interactionType: String) {
        logEvent("course_card_interaction", parameters: [
            "course_id": courseId,
            "course_title": courseTitle,
            "interaction_type": interactionType, // "tap", "scroll", "view"
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Course card \(interactionType) - \(courseTitle)")
    }
    
    /// Track recommendations sheet opened
    func trackRecommendationsOpened() {
        logEvent("recommendations_opened", parameters: [
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Recommendations sheet opened")
    }
    
    // MARK: - Conversation Flow Analytics
    
    /// Track conversation path taken
    func trackConversationPath(
        intent: String,
        clarificationNeeded: Bool,
        levelSelected: String,
        timeToComplete: Double
    ) {
        logEvent("conversation_path", parameters: [
            "intent": intent,
            "clarification_needed": clarificationNeeded,
            "level_selected": levelSelected,
            "time_to_complete": timeToComplete,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Conversation path - \(intent), clarify: \(clarificationNeeded)")
    }
    
    /// Track learning hub screen view
    func trackScreenView(screenName: String) {
        logEvent("screen_view", parameters: [
            "screen_name": screenName,
            "screen_class": "LearningHubLandingView",
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        print("📊 Analytics: Screen view - \(screenName)")
    }
    
    // MARK: - User Preferences
    
    /// Track topic interest (for personalization)
    func trackTopicInterest(topic: String, category: String) {
        logEvent("topic_interest", parameters: [
            "topic": topic,
            "category": category,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        
        // Store in UserDefaults for personalization
        var interests = UserDefaults.standard.stringArray(forKey: "user_topic_interests") ?? []
        if !interests.contains(topic) {
            interests.append(topic)
            UserDefaults.standard.set(interests, forKey: "user_topic_interests")
        }
        
        print("📊 Analytics: Topic interest - \(topic)")
    }
    
    /// Track preferred learning level
    func trackLevelPreference(level: String) {
        logEvent("level_preference", parameters: [
            "level": level,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": getCurrentSessionId()
        ])
        
        // Store in UserDefaults for personalization
        UserDefaults.standard.set(level, forKey: "preferred_learning_level")
        
        print("📊 Analytics: Level preference - \(level)")
    }
    
    // MARK: - Session Management
    
    private func getCurrentSessionId() -> String {
        if let sessionId = UserDefaults.standard.string(forKey: "current_session_id") {
            return sessionId
        } else {
            let newSessionId = UUID().uuidString
            UserDefaults.standard.set(newSessionId, forKey: "current_session_id")
            return newSessionId
        }
    }
    
    /// Start new session
    func startNewSession() {
        let sessionId = UUID().uuidString
        UserDefaults.standard.set(sessionId, forKey: "current_session_id")
        
        logEvent("session_started", parameters: [
            "session_id": sessionId,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        print("📊 Analytics: New session started - \(sessionId)")
    }
    
    /// End session
    func endSession() {
        if let sessionId = UserDefaults.standard.string(forKey: "current_session_id") {
            logEvent("session_ended", parameters: [
                "session_id": sessionId,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            print("📊 Analytics: Session ended - \(sessionId)")
        }
        
        UserDefaults.standard.removeObject(forKey: "current_session_id")
    }
}

// MARK: - Analytics Event Types
enum AnalyticsEventType {
    case conversationStarted
    case userMessage
    case aiResponse
    case quickActionSelected
    case courseGenerationStarted
    case courseGenerationCompleted
    case courseGenerationFailed
    case countdownStarted
    case courseLaunched
    case voiceInputUsed
    case courseCardInteraction
    case recommendationsOpened
    case conversationPath
    case screenView
    case topicInterest
    case levelPreference
}
