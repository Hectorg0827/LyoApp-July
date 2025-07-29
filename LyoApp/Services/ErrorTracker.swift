import Foundation
import OSLog

// MARK: - Error Tracker Service
@MainActor
class ErrorTracker: ObservableObject {
    static let shared = ErrorTracker()
    
    private let logger = Logger(subsystem: "com.lyoapp.errortracker", category: "errors")
    private var errorQueue: [TrackedError] = []
    private let maxQueueSize = 100
    
    private init() {}
    
    // MARK: - Error Tracking
    func trackError(_ error: Error, context: String = "", userId: String? = nil) {
        let trackedError = TrackedError(
            error: error,
            context: context,
            userId: userId,
            timestamp: Date()
        )
        
        // Log to system
        logger.error("Error tracked: \(error.localizedDescription) | Context: \(context)")
        
        // Add to queue
        errorQueue.append(trackedError)
        
        // Maintain queue size
        if errorQueue.count > maxQueueSize {
            errorQueue.removeFirst()
        }
        
        // Send to analytics (if available)
        #if !DEBUG
        sendToAnalytics(trackedError)
        #endif
    }
    
    // MARK: - Error Retrieval
    func getRecentErrors(limit: Int = 10) -> [TrackedError] {
        return Array(errorQueue.suffix(limit))
    }
    
    func clearErrors() {
        errorQueue.removeAll()
    }
    
    // MARK: - Private Methods
    private func sendToAnalytics(_ error: TrackedError) {
        // In a real implementation, this would send to your analytics service
        // For now, we'll just use the AnalyticsManager
        AnalyticsManager.shared.trackUserAction("error_occurred", parameters: [
            "error_domain": error.error.localizedDescription,
            "context": error.context,
            "timestamp": error.timestamp.timeIntervalSince1970,
            "user_id": error.userId ?? "unknown"
        ])
    }
}

// MARK: - Tracked Error Model
struct TrackedError: Identifiable, Codable {
    let id = UUID()
    let errorDescription: String
    let context: String
    let userId: String?
    let timestamp: Date
    
    // Computed property for the actual error (not stored due to Codable requirements)
    var error: Error {
        return NSError(domain: "TrackedError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription])
    }
    
    init(error: Error, context: String, userId: String?, timestamp: Date) {
        self.errorDescription = error.localizedDescription
        self.context = context
        self.userId = userId
        self.timestamp = timestamp
    }
}

// MARK: - Error Categories
enum ErrorCategory: String, CaseIterable {
    case network = "network"
    case authentication = "authentication"
    case dataStorage = "data_storage"
    case userInterface = "user_interface"
    case api = "api"
    case unknown = "unknown"
    
    static func categorize(_ error: Error) -> ErrorCategory {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("network") || errorString.contains("connection") {
            return .network
        } else if errorString.contains("auth") || errorString.contains("token") {
            return .authentication
        } else if errorString.contains("data") || errorString.contains("storage") {
            return .dataStorage
        } else if errorString.contains("api") || errorString.contains("server") {
            return .api
        } else {
            return .unknown
        }
    }
}
