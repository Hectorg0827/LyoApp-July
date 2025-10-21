import Foundation
import SwiftUI
import Combine

/// Orchestrates all real-time learning features via WebSocket
@MainActor
class LiveLearningOrchestrator: ObservableObject {
    static let shared = LiveLearningOrchestrator()
    
    // MARK: - Published State
    @Published var aiResponse: String = ""
    @Published var isAIThinking: Bool = false
    @Published var suggestedActions: [String] = []
    @Published var realtimeProgress: Float = 0
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // MARK: - Private Properties
    private var websocket: WebSocketService
    private var cancellables = Set<AnyCancellable>()
    private var currentLesson: Lesson?
    private var conversationHistory: [LiveChatMessage] = []
    
    // MARK: - Initialization
    private init() {
        self.websocket = WebSocketService()
        setupRealtimeHandlers()
    }
    
    // MARK: - WebSocket Setup
    private func setupRealtimeHandlers() {
        // Subscribe to WebSocket receivedMessage changes
        websocket.$receivedMessage
            .compactMap { $0 }
            .sink { [weak self] messageString in
                self?.handleWebSocketMessageString(messageString)
            }
            .store(in: &cancellables)
    }
    
    private func connectWebSocket() {
        // Note: WebSocketService.connect requires userId parameter
        // This should be called after user authentication
        // For now, we'll defer connection until needed
        connectionStatus = .disconnected
        print("⚠️ [LiveLearning] WebSocket not connected - requires userId")
    }
    
    func connect(userId: String) {
        websocket.connect(userId: userId)
        connectionStatus = .connected
        print("✅ [LiveLearning] WebSocket connected for user: \(userId)")
    }
    
    // MARK: - Message Handling
    private func handleWebSocketMessageString(_ messageString: String) {
        guard let data = messageString.data(using: .utf8),
              let json = try? JSONDecoder().decode(LiveWebSocketMessage.self, from: data) else {
            print("⚠️ [LiveLearning] Failed to decode message")
            return
        }
        handleWebSocketMessage(json)
    }
    
    private func handleWebSocketMessage(_ message: LiveWebSocketMessage) {
        switch message.type {
        case "ai_thinking":
            isAIThinking = true
            
        case "ai_response":
            isAIThinking = false
            if let content = message.content {
                aiResponse = content
                addToHistory(content: content, isFromUser: false)
            }
            
        case "progress_update":
            if let progress = message.progress {
                realtimeProgress = progress
            }
            
        case "struggle_detected":
            handleStruggleDetected(message)
            
        case "concept_mastered":
            handleConceptMastered(message)
            
        case "suggested_actions":
            if let actions = message.actions {
                suggestedActions = actions
            }
            
        default:
            print("⚠️ [LiveLearning] Unknown message type: \(message.type)")
        }
    }
    
    // MARK: - User Interaction
    func askQuestion(_ question: String) {
        guard connectionStatus == .connected else {
            print("⚠️ [LiveLearning] Not connected to WebSocket")
            return
        }
        
        addToHistory(content: question, isFromUser: true)
        
        let payload: [String: Any] = [
            "type": "user_question",
            "question": question,
            "context": currentLesson?.id.uuidString ?? "",
            "history": conversationHistory.suffix(10).map { $0.toDictionary() }
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            websocket.sendMessage(message: jsonString)
        }
    }
    
    func setCurrentLesson(_ lesson: Lesson) {
        self.currentLesson = lesson
        
        // Notify backend of context change
        let payload: [String: Any] = [
            "type": "context_update",
            "lesson_id": lesson.id.uuidString,
            "lesson_title": lesson.title
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            websocket.sendMessage(message: jsonString)
        }
    }
    
    func reportProgress(percentage: Float) {
        let payload: [String: Any] = [
            "type": "progress_report",
            "lesson_id": currentLesson?.id.uuidString ?? "",
            "percentage": percentage
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            websocket.sendMessage(message: jsonString)
        }
    }
    
    // MARK: - Event Handlers
    private func handleStruggleDetected(_ message: LiveWebSocketMessage) {
        print("🆘 [LiveLearning] Struggle detected: \(message.context ?? "")")
        
        // Trigger proactive help
        if let suggestions = message.suggestions {
            suggestedActions = suggestions
        }
        
        // Post notification for UI to respond
        NotificationCenter.default.post(
            name: .userStrugglingWithConcept,
            object: message.context
        )
    }
    
    private func handleConceptMastered(_ message: LiveWebSocketMessage) {
        print("🎉 [LiveLearning] Concept mastered: \(message.achievement ?? "")")
        
        // Trigger celebration
        NotificationCenter.default.post(
            name: .userMasteredConcept,
            object: message.achievement
        )
    }
    
    // MARK: - History Management
    private func addToHistory(content: String, isFromUser: Bool) {
        let message = LiveChatMessage(
            id: UUID().uuidString,
            content: content,
            isFromUser: isFromUser,
            timestamp: Date()
        )
        conversationHistory.append(message)
        
        // Keep last 50 messages
        if conversationHistory.count > 50 {
            conversationHistory.removeFirst()
        }
    }
    
    func clearHistory() {
        conversationHistory.removeAll()
    }
    
    // MARK: - Connection Management
    func reconnect() {
        websocket.disconnect()
        connectWebSocket()
    }
    
    func disconnect() {
        websocket.disconnect()
        connectionStatus = .disconnected
    }
}

// MARK: - Supporting Types
enum ConnectionStatus {
    case connected
    case disconnected
    case connecting
    case error
    
    var statusText: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .error: return "Connection Error"
        }
    }
}

struct LiveWebSocketMessage: Codable {
    let type: String
    let content: String?
    let progress: Float?
    let context: String?
    let achievement: String?
    let suggestions: [String]?
    let actions: [String]?
}

struct LiveChatMessage: Codable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "content": content,
            "is_from_user": isFromUser,
            "timestamp": ISO8601DateFormatter().string(from: timestamp)
        ]
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userStrugglingWithConcept = Notification.Name("userStrugglingWithConcept")
    static let userMasteredConcept = Notification.Name("userMasteredConcept")
}
