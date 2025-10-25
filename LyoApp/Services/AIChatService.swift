import Foundation
import Combine
import os.log

// MARK: - AI Chat Service

@MainActor
class AIChatService: ObservableObject {
    
    static let shared = AIChatService()
    
    @Published var isThinking: Bool = false
    @Published var currentConversationId: String?
    @Published var messages: [ChatMessage] = []
    @Published var lastError: Error?
    
    private let apiClient = APIClient.shared
    private let webSocketManager = WebSocketManager.shared
    private let logger = Logger(subsystem: "com.lyoapp", category: "AIChat")
    
    private var cancellables = Set<AnyCancellable>()
    private var wsSubscription: AnyCancellable?
    
    private init() {}
    
    // MARK: - Send Message to AI
    
    /// Send a message to the AI mentor and get a response
    /// - Parameters:
    ///   - message: The user's message
    ///   - userId: The user ID
    ///   - context: Optional conversation context (lesson, avatar personality, etc.)
    ///   - model: AI model to use (default: gemini-2.0-flash-exp)
    /// - Returns: The AI's response
    func sendMessage(
        _ message: String,
        userId: Int,
        context: ConversationContext? = nil,
        model: AIModel = .gemini
    ) async throws -> String {
        logger.info("💬 Sending message to AI: \(message.prefix(50))...")
        
        isThinking = true
        lastError = nil
        
        defer {
            isThinking = false
        }
        
        // Add user message to local history
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: message,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Build request
        let chatContext = context.flatMap { ctx in
            ChatContext(
                currentLesson: ctx.currentLesson,
                userLevel: ctx.userLevel,
                avatarPersonality: ctx.avatarPersonality,
                conversationId: currentConversationId
            )
        }
        
        let request = AIChatRequest(
            userId: userId,
            message: message,
            model: model.rawValue,
            context: chatContext
        )
        
        do {
            // Call API
            let response: AIChatResponse = try await apiClient.post(
                "/api/v1/ai/mentor/conversation",
                body: request,
                requiresAuth: false
            )
            
            logger.info("✅ Received AI response (\(response.tokensUsed ?? 0) tokens, \(response.responseTimeMs ?? 0)ms)")
            
            // Update conversation ID
            if let conversationId = response.conversationId {
                currentConversationId = conversationId
            }
            
            // Add AI response to local history
            let aiMessage = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                content: response.response,
                timestamp: Date(),
                model: response.modelUsed,
                tokensUsed: response.tokensUsed
            )
            messages.append(aiMessage)
            
            return response.response
            
        } catch {
            logger.error("❌ AI chat error: \(error.localizedDescription)")
            lastError = error
            throw error
        }
    }
    
    // MARK: - Real-Time Chat (WebSocket)
    
    /// Subscribe to real-time AI chat via WebSocket
    /// - Parameter userId: The user ID
    func subscribeToRealTimeChat(userId: Int) {
        logger.info("🔌 Subscribing to real-time AI chat for user \(userId)")
        
        // TODO: Implement after WebSocketManager is updated to support channel-specific connections
        // For now, use HTTP polling
        logger.warning("⚠️ WebSocket not yet implemented for AI chat - using HTTP polling")
    }
    
    /// Unsubscribe from real-time chat
    func unsubscribeFromRealTimeChat() {
        wsSubscription?.cancel()
        wsSubscription = nil
        logger.info("🔌 Unsubscribed from real-time AI chat")
    }
    
    // MARK: - Conversation History
    
    /// Load conversation history from backend
    /// - Parameters:
    ///   - userId: The user ID
    ///   - limit: Maximum number of conversations to fetch
    func loadConversationHistory(userId: Int, limit: Int = 50) async throws {
        logger.info("📚 Loading conversation history for user \(userId)")
        
        let params: [String: Any] = [
            "user_id": userId,
            "limit": limit
        ]
        
        let response: ConversationHistory = try await apiClient.get(
            "/api/v1/ai/mentor/history",
            parameters: params,
            requiresAuth: false
        )
        
        // Convert to local message format
        if let lastConversation = response.conversations.first {
            currentConversationId = lastConversation.id
            messages = lastConversation.messages.map { dto in
                ChatMessage(
                    id: dto.id,
                    role: dto.role == "user" ? .user : .assistant,
                    content: dto.content,
                    timestamp: ISO8601DateFormatter().date(from: dto.timestamp) ?? Date(),
                    model: dto.model
                )
            }
        }
        
        logger.info("✅ Loaded \(messages.count) messages")
    }
    
    // MARK: - Clear Conversation
    
    func clearConversation() {
        messages.removeAll()
        currentConversationId = nil
        logger.info("🗑️ Conversation cleared")
    }
    
    // MARK: - Helper Methods
    
    /// Get conversation preview (first and last message)
    func getConversationPreview() -> (first: String, last: String)? {
        guard let first = messages.first, let last = messages.last else {
            return nil
        }
        return (first.content, last.content)
    }
    
    /// Count messages in current conversation
    var messageCount: Int {
        messages.count
    }
}

// MARK: - AI Models

enum AIModel: String {
    case gemini = "gemini-2.0-flash-exp"
    case gpt4 = "gpt-4"
    case claude = "claude-3"
    
    var displayName: String {
        switch self {
        case .gemini:
            return "Gemini 2.0 Flash"
        case .gpt4:
            return "GPT-4"
        case .claude:
            return "Claude 3"
        }
    }
}

// MARK: - Chat Message Model
// Using canonical ChatMessage from Models/ChatMessage.swift
// Deleted duplicate - use: typealias ChatMessage = AIMessage

// MARK: - Conversation Context

struct ConversationContext {
    let currentLesson: String?
    let userLevel: String?
    let avatarPersonality: String?
    let additionalContext: [String: String]?
    
    init(
        currentLesson: String? = nil,
        userLevel: String? = nil,
        avatarPersonality: String? = nil,
        additionalContext: [String: String]? = nil
    ) {
        self.currentLesson = currentLesson
        self.userLevel = userLevel
        self.avatarPersonality = avatarPersonality
        self.additionalContext = additionalContext
    }
}

// MARK: - Chat View Helper

extension AIChatService {
    
    /// Send message and handle errors gracefully for UI
    func sendMessageSafely(
        _ message: String,
        userId: Int,
        context: ConversationContext? = nil
    ) async -> String {
        do {
            return try await sendMessage(message, userId: userId, context: context)
        } catch {
            logger.error("Chat error: \(error.localizedDescription)")
            return "I'm having trouble connecting right now. Please try again in a moment."
        }
    }
    
    /// Get avatar personality-appropriate greeting
    func getGreeting(for personality: String) -> String {
        switch personality.lowercased() {
        case "wise", "mentor":
            return "Hello, young learner. What would you like to explore today?"
        case "friendly", "companion":
            return "Hey there! I'm excited to learn with you today. What's on your mind?"
        case "energetic", "motivator":
            return "Let's do this! What awesome topic are we tackling today?"
        case "calm", "patient":
            return "Take your time. I'm here to help. What would you like to learn about?"
        default:
            return "Hi! I'm here to help you learn. What would you like to know?"
        }
    }
    
    /// Get suggested questions based on context
    func getSuggestedQuestions(for lesson: String?) -> [String] {
        guard let lesson = lesson else {
            return [
                "Can you explain this topic?",
                "Show me an example",
                "I'm confused about this",
                "What's the next step?"
            ]
        }
        
        return [
            "Can you explain \(lesson) in simpler terms?",
            "Show me a real-world example of \(lesson)",
            "What are common mistakes with \(lesson)?",
            "How does \(lesson) relate to what I learned before?"
        ]
    }
}

// MARK: - SwiftUI Extensions

extension ChatMessage {
    /// Format timestamp for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: timestamp)
    }
}
