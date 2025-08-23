import Foundation
import OSLog

/// Static Analytics facade for easy event tracking throughout the app
enum Analytics {
    private static let logger = Logger(subsystem: "com.lyo.app", category: "Analytics")
    
    /// Log an analytics event
    static func log(_ name: String, _ props: [String: Any] = [:]) {
        #if DEBUG
        logger.info("📊 [Analytics] \(name, privacy: .public) \(String(describing: props), privacy: .auto)")
        #endif
        
        // Forward to the main analytics manager for batching and sending
        Task { @MainActor in
            AnalyticsManager.shared.track(name, properties: props)
        }
    }
}

/// Analytics and telemetry manager for tracking user events and app performance
@MainActor
class AnalyticsManager: ObservableObject {
    
    static let shared = AnalyticsManager()
    
    private let logger = Logger(subsystem: "com.lyo.app", category: "Analytics")
    private let apiClient: APIClient
    private let isEnabled: Bool
    
    // Event batching
    private var eventQueue: [AnalyticsEvent] = []
    private let batchSize = 10
    private let flushInterval: TimeInterval = 30 // 30 seconds
    private var flushTimer: Timer?
    
    // Network logging
    @Published var networkLogs: [NetworkLog] = []
    private let maxNetworkLogs = 50
    
    init(apiClient: APIClient? = nil) {
        // Analytics enabled in production, debug mode based on config
        #if DEBUG
        self.isEnabled = true // Keep enabled for development
        #else
        self.isEnabled = true
        #endif
        
        let authManager = AuthManager()
        self.apiClient = apiClient ?? APIClient(environment: .current, authManager: authManager)
        
        setupPeriodicFlush()
        
        print("📊 Analytics initialized (enabled: \(isEnabled))")
    }
    
    deinit {
        flushTimer?.invalidate()
        flushEvents()
    }
    
    // MARK: - Event Tracking
    
    /// Track a custom event
    func track(_ eventName: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        let event = AnalyticsEvent(
            name: eventName,
            properties: properties,
            timestamp: Date()
        )
        
        eventQueue.append(event)
        logger.info("📊 Event tracked: \(eventName)")
        
        // Flush if batch size reached
        if eventQueue.count >= batchSize {
            flushEvents()
        }
    }
    
    /// Track screen view
    func trackScreenView(_ screenName: String, properties: [String: Any] = [:]) {
        var props = properties
        props["screen_name"] = screenName
        track("screen_view", properties: props)
    }
    
    /// Track course generation events
    func trackCourseGenerationRequested(topic: String, interests: [String]) {
        track("course_generate_requested", properties: [
            "topic": topic,
            "interests": interests,
            "interests_count": interests.count
        ])
    }
    
    func trackCourseGenerationReady(taskId: String, duration: TimeInterval) {
        track("course_generate_ready", properties: [
            "task_id": taskId,
            "generation_duration_seconds": duration
        ])
    }
    
    func trackCourseGenerationTimeout(taskId: String, duration: TimeInterval) {
        track("course_generate_timeout", properties: [
            "task_id": taskId,
            "timeout_duration_seconds": duration
        ])
    }
    
    /// Track content interaction
    func trackContentItemOpened(itemId: String, type: String, source: String) {
        track("content_item_opened", properties: [
            "item_id": itemId,
            "content_type": type,
            "source": source
        ])
    }
    
    /// Track feed events
    func trackFeedPageLoaded(itemCount: Int, hasMore: Bool) {
        track("feed_page_loaded", properties: [
            "item_count": itemCount,
            "has_more_pages": hasMore
        ])
    }
    
    /// Track API errors
    func trackAPIError(endpoint: String, statusCode: Int, errorType: String) {
        track("api_error", properties: [
            "endpoint": endpoint,
            "status_code": statusCode,
            "error_type": errorType
        ])
    }
    
    /// Track user engagement
    func trackSessionStart() {
        track("session_start")
    }
    
    func trackSessionEnd(duration: TimeInterval) {
        track("session_end", properties: [
            "session_duration_seconds": duration
        ])
    }
    
    // MARK: - Network Logging
    
    /// Log network request for debugging
    func logNetworkRequest(
        method: String,
        url: String,
        statusCode: Int,
        duration: TimeInterval,
        error: String? = nil
    ) {
        #if DEBUG
        let log = NetworkLog(
            timestamp: Date(),
            method: method,
            url: redactSensitiveInfo(from: url),
            statusCode: statusCode,
            duration: duration,
            error: error
        )
        
        networkLogs.append(log)
        
        // Limit log size
        if networkLogs.count > maxNetworkLogs {
            networkLogs.removeFirst(networkLogs.count - maxNetworkLogs)
        }
        
        // Log to console
        let status = statusCode >= 400 ? "❌" : "✅"
        logger.debug("\(status) \(method) \(log.url) (\(statusCode)) - \(String(format: "%.2f", duration))s")
        
        if let error = error {
            logger.error("Error: \(error)")
        }
        #endif
    }
    
    // MARK: - Event Flushing
    
    private func setupPeriodicFlush() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { _ in
            self.flushEvents()
        }
    }
    
    private func flushEvents() {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToSend = eventQueue
        eventQueue.removeAll()
        
        logger.info("📤 Flushing \(eventsToSend.count) analytics events")
        
        Task {
            await sendEvents(eventsToSend)
        }
    }
    
    private func sendEvents(_ events: [AnalyticsEvent]) async {
        guard isEnabled else { return }
        
        do {
            let request = AnalyticsRequest(events: events)
            let _: AnalyticsResponse = try await apiClient.post("analytics/events", body: request)
            
            logger.info("✅ Analytics events sent successfully")
            
        } catch {
            logger.error("❌ Failed to send analytics events: \(error)")
            
            // Re-queue events for retry (with limit to prevent infinite growth)
            if eventQueue.count < batchSize * 5 {
                eventQueue.insert(contentsOf: events, at: 0)
            }
        }
    }
    
    // MARK: - Privacy & Security
    
    /// Redact sensitive information from URLs and data
    private func redactSensitiveInfo(from url: String) -> String {
        var redactedURL = url
        
        // Redact access tokens
        redactedURL = redactedURL.replacingOccurrences(
            of: "access_token=[^&]+",
            with: "access_token=[REDACTED]",
            options: .regularExpression
        )
        
        // Redact API keys
        redactedURL = redactedURL.replacingOccurrences(
            of: "api_key=[^&]+",
            with: "api_key=[REDACTED]",
            options: .regularExpression
        )
        
        return redactedURL
    }
    
    // MARK: - Debug Methods
    
    /// Get recent network logs for debug screen
    func getRecentNetworkLogs() -> [NetworkLog] {
        return Array(networkLogs.suffix(20))
    }
    
    /// Clear network logs
    func clearNetworkLogs() {
        networkLogs.removeAll()
    }
    
    /// Force flush events for testing
    func forceFlush() {
        flushEvents()
    }
}

// MARK: - Analytics Models
struct AnalyticsEvent: Codable {
    let name: String
    let properties: [String: AnyCodable]
    let timestamp: Date
    let sessionId: String
    let userId: String?
    let deviceInfo: DeviceInfo
    
    init(name: String, properties: [String: Any], timestamp: Date) {
        self.name = name
        self.properties = properties.mapValues { AnyCodable($0) }
        self.timestamp = timestamp
        self.sessionId = AnalyticsSession.current.id
        self.userId = nil // Will be set by backend if user is authenticated
        self.deviceInfo = DeviceInfo.current
    }
}

struct DeviceInfo: Codable {
    let platform: String
    let osVersion: String
    let appVersion: String
    let deviceModel: String
    
    static var current: DeviceInfo {
        return DeviceInfo(
            platform: "iOS",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            deviceModel: UIDevice.current.model
        )
    }
}

struct AnalyticsSession {
    let id: String
    let startTime: Date
    
    static var current = AnalyticsSession(
        id: UUID().uuidString,
        startTime: Date()
    )
}

struct NetworkLog: Identifiable {
    let id = UUID()
    let timestamp: Date
    let method: String
    let url: String
    let statusCode: Int
    let duration: TimeInterval
    let error: String?
    
    var formattedDuration: String {
        return String(format: "%.2fs", duration)
    }
    
    var statusColor: String {
        switch statusCode {
        case 200..<300: return "green"
        case 300..<400: return "orange"
        case 400..<500: return "red"
        case 500..<600: return "purple"
        default: return "gray"
        }
    }
}

// MARK: - Request/Response Models
private struct AnalyticsRequest: Codable {
    let events: [AnalyticsEvent]
}

private struct AnalyticsResponse: Codable {
    let received: Int
    let processed: Int
}

// MARK: - Helper for Any Codable
struct AnyCodable: Codable {
    private let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encode(String(describing: value))
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }
}