import SwiftUI
import Foundation
import Combine

// MARK: - Analytics Infrastructure

/// Central analytics manager for tracking user interactions and app performance
@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @Published var isEnabled = true
    @Published var debugMode = false
    
    private var eventQueue: [AnalyticsEvent] = []
    private var sessionId: String = UUID().uuidString
    private var sessionStartTime: Date = Date()
    private let maxQueueSize = 100
    private let batchSize = 20
    
    private init() {
        startAnalyticsSession()
        setupEventProcessing()
    }
    
    // MARK: - Session Management
    
    private func startAnalyticsSession() {
        sessionId = UUID().uuidString
        sessionStartTime = Date()
        
        trackEvent(.sessionStart(
            sessionId: sessionId,
            deviceInfo: DeviceInfo.current,
            appVersion: AppInfo.version
        ))
    }
    
    func endSession() {
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        trackEvent(.sessionEnd(
            sessionId: sessionId,
            duration: sessionDuration
        ))
        flushEvents()
    }
    
    // MARK: - Event Tracking
    
    func trackEvent(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        
        let enrichedEvent = enrichEvent(event)
        eventQueue.append(enrichedEvent)
        
        if debugMode {
            print("📊 Analytics: \(enrichedEvent.name) - \(enrichedEvent.parameters)")
        }
        
        // Auto-flush when queue is full
        if eventQueue.count >= maxQueueSize {
            flushEvents()
        }
    }
    
    private func enrichEvent(_ event: AnalyticsEvent) -> AnalyticsEvent {
        var enrichedEvent = event
        enrichedEvent.timestamp = Date()
        enrichedEvent.sessionId = sessionId
        enrichedEvent.parameters["app_version"] = AppInfo.version
        enrichedEvent.parameters["platform"] = "iOS"
        return enrichedEvent
    }
    
    // MARK: - Batch Processing
    
    private func setupEventProcessing() {
        // Process events every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                self.processEventQueue()
            }
        }
    }
    
    private func processEventQueue() {
        guard !eventQueue.isEmpty else { return }
        
        let batchToProcess = Array(eventQueue.prefix(batchSize))
        eventQueue.removeFirst(min(batchSize, eventQueue.count))
        
        Task.detached {
            await self.sendEvents(batchToProcess)
        }
    }
    
    private func flushEvents() {
        guard !eventQueue.isEmpty else { return }
        
        let allEvents = eventQueue
        eventQueue.removeAll()
        
        Task.detached {
            await self.sendEvents(allEvents)
        }
    }
    
    private func sendEvents(_ events: [AnalyticsEvent]) async {
        // Simulate sending to analytics service
        do {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            if debugMode {
                await MainActor.run {
                    print("📊 Analytics: Sent \(events.count) events to server")
                }
            }
        } catch {
            await MainActor.run {
                print("📊 Analytics Error: Failed to send events - \(error)")
            }
        }
    }
}

// MARK: - Analytics Event Model

struct AnalyticsEvent {
    let name: String
    var parameters: [String: Any]
    var timestamp: Date?
    var sessionId: String?
    
    init(name: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

// MARK: - Predefined Analytics Events

extension AnalyticsEvent {
    // MARK: - Session Events
    static func sessionStart(sessionId: String, deviceInfo: DeviceInfo, appVersion: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "session_start", parameters: [
            "session_id": sessionId,
            "device_model": deviceInfo.model,
            "os_version": deviceInfo.osVersion,
            "app_version": appVersion,
            "screen_size": deviceInfo.screenSize
        ])
    }
    
    static func sessionEnd(sessionId: String, duration: TimeInterval) -> AnalyticsEvent {
        AnalyticsEvent(name: "session_end", parameters: [
            "session_id": sessionId,
            "duration": duration
        ])
    }
    
    // MARK: - Navigation Events
    static func screenView(screenName: String, previousScreen: String? = nil) -> AnalyticsEvent {
        var parameters: [String: Any] = ["screen_name": screenName]
        if let previous = previousScreen {
            parameters["previous_screen"] = previous
        }
        return AnalyticsEvent(name: "screen_view", parameters: parameters)
    }
    
    static func tabSwitch(fromTab: String, toTab: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "tab_switch", parameters: [
            "from_tab": fromTab,
            "to_tab": toTab
        ])
    }
    
    // MARK: - Learning Events
    static func courseStart(topic: String, difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "course_start", parameters: [
            "topic": topic,
            "difficulty": difficulty
        ])
    }
    
    static func chapterProgress(topic: String, chapterIndex: Int, totalChapters: Int, progress: Double) -> AnalyticsEvent {
        AnalyticsEvent(name: "chapter_progress", parameters: [
            "topic": topic,
            "chapter_index": chapterIndex,
            "total_chapters": totalChapters,
            "progress": progress
        ])
    }
    
    static func quizStart(topic: String, chapterTitle: String, questionCount: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "quiz_start", parameters: [
            "topic": topic,
            "chapter_title": chapterTitle,
            "question_count": questionCount
        ])
    }
    
    static func quizAnswer(questionIndex: Int, isCorrect: Bool, timeTaken: TimeInterval) -> AnalyticsEvent {
        AnalyticsEvent(name: "quiz_answer", parameters: [
            "question_index": questionIndex,
            "is_correct": isCorrect,
            "time_taken": timeTaken
        ])
    }
    
    static func quizComplete(topic: String, score: Int, totalQuestions: Int, timeTaken: TimeInterval) -> AnalyticsEvent {
        AnalyticsEvent(name: "quiz_complete", parameters: [
            "topic": topic,
            "score": score,
            "total_questions": totalQuestions,
            "accuracy": Double(score) / Double(totalQuestions),
            "time_taken": timeTaken
        ])
    }
    
    // MARK: - AI Chat Events
    static func aiChatStart(topic: String, chapterTitle: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "ai_chat_start", parameters: [
            "topic": topic,
            "chapter_title": chapterTitle
        ])
    }
    
    static func aiMessage(messageLength: Int, responseTime: TimeInterval) -> AnalyticsEvent {
        AnalyticsEvent(name: "ai_message", parameters: [
            "message_length": messageLength,
            "response_time": responseTime
        ])
    }
    
    // MARK: - Social Events
    static func feedView(postCount: Int, loadTime: TimeInterval) -> AnalyticsEvent {
        AnalyticsEvent(name: "feed_view", parameters: [
            "post_count": postCount,
            "load_time": loadTime
        ])
    }
    
    static func postInteraction(action: String, postId: String, authorId: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "post_interaction", parameters: [
            "action": action, // like, comment, share
            "post_id": postId,
            "author_id": authorId
        ])
    }
    
    static func postCreate(contentLength: Int, hasImage: Bool, hasVideo: Bool) -> AnalyticsEvent {
        AnalyticsEvent(name: "post_create", parameters: [
            "content_length": contentLength,
            "has_image": hasImage,
            "has_video": hasVideo
        ])
    }
    
    // MARK: - Discovery Events
    static func search(query: String, resultCount: Int, searchTime: TimeInterval) -> AnalyticsEvent {
        AnalyticsEvent(name: "search", parameters: [
            "query": query,
            "result_count": resultCount,
            "search_time": searchTime
        ])
    }
    
    static func categoryFilter(category: String, resultCount: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "category_filter", parameters: [
            "category": category,
            "result_count": resultCount
        ])
    }
    
    // MARK: - Performance Events
    static func performanceMetric(viewName: String, loadTime: TimeInterval, memoryUsage: UInt64) -> AnalyticsEvent {
        AnalyticsEvent(name: "performance_metric", parameters: [
            "view_name": viewName,
            "load_time": loadTime,
            "memory_usage": memoryUsage
        ])
    }
    
    static func error(errorType: String, errorMessage: String, context: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "error", parameters: [
            "error_type": errorType,
            "error_message": errorMessage,
            "context": context
        ])
    }
}

// MARK: - Device Information

struct DeviceInfo {
    let model: String
    let osVersion: String
    let screenSize: String
    
    static var current: DeviceInfo {
        DeviceInfo(
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            screenSize: "\(Int(UIScreen.main.bounds.width))x\(Int(UIScreen.main.bounds.height))"
        )
    }
}

// MARK: - App Information

struct AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

// MARK: - Analytics View Modifier

struct AnalyticsTrackingModifier: ViewModifier {
    let screenName: String
    let previousScreen: String?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                AnalyticsManager.shared.trackEvent(.screenView(
                    screenName: screenName,
                    previousScreen: previousScreen
                ))
            }
    }
}

extension View {
    func trackScreenView(_ screenName: String, previousScreen: String? = nil) -> some View {
        modifier(AnalyticsTrackingModifier(screenName: screenName, previousScreen: previousScreen))
    }
}

// MARK: - Performance Analytics Tracker

class PerformanceTracker {
    private var startTime: Date?
    private var viewName: String
    
    init(viewName: String) {
        self.viewName = viewName
    }
    
    func startTracking() {
        startTime = Date()
    }
    
    func endTracking(memoryUsage: UInt64 = 0) {
        guard let startTime = startTime else { return }
        let loadTime = Date().timeIntervalSince(startTime)
        
        AnalyticsManager.shared.trackEvent(.performanceMetric(
            viewName: viewName,
            loadTime: loadTime,
            memoryUsage: memoryUsage
        ))
        
        self.startTime = nil
    }
}

// MARK: - A/B Testing Support

enum ABTestVariant: String, CaseIterable {
    case control = "control"
    case variantA = "variant_a"
    case variantB = "variant_b"
}

class ABTestManager {
    static let shared = ABTestManager()
    
    private var userVariants: [String: ABTestVariant] = [:]
    
    private init() {}
    
    func getVariant(for testName: String) -> ABTestVariant {
        if let existingVariant = userVariants[testName] {
            return existingVariant
        }
        
        // Randomly assign variant (simplified)
        let variant = ABTestVariant.allCases.randomElement() ?? .control
        userVariants[testName] = variant
        
        // Track assignment
        AnalyticsManager.shared.trackEvent(AnalyticsEvent(
            name: "ab_test_assignment",
            parameters: [
                "test_name": testName,
                "variant": variant.rawValue
            ]
        ))
        
        return variant
    }
}
