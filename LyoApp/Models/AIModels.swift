import Foundation
import SwiftUI

// This file holds ONLY view models & services. Data model structs like `AIMessage` live in Models/.

struct AIPersonality: Codable, Equatable {
    let name: String
    let avatar: String
    let description: String
    let expertise: [String]
    let tone: String
    static let lyo = AIPersonality(
        name: "Lyo",
        avatar: "lightbulb.circle.fill",
        description: "Your personalized AI learning companion and Socratic tutor",
        expertise: ["Programming", "Design", "Technology", "Learning Strategies", "Critical Thinking", "Problem Solving"],
        tone: "Patient, inquisitive, encouraging, and Socratic"
    )
}

@MainActor
final class AIConversationViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isTyping = false
    @Published var currentInput = ""
    @Published var personality: AIPersonality = .lyo
    @Published var generatedCourse: Course? = nil // For intelligent course creation
    
    init() { addWelcomeMessage() }
    
    private func addWelcomeMessage() {
        messages.append(AIMessage(content: "Hello! I'm Lyo – your AI learning companion. What would you like to explore today?", isFromUser: false))
    }
    
    func sendMessage(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(AIMessage(content: trimmed, isFromUser: true))
        currentInput = ""
        generateAIResponse(to: trimmed)
    }
    
    private func generateAIResponse(to userMessage: String) {
        isTyping = true

        Task { [weak self] in
            do {
                // Call the intelligent AI endpoint that can handle both explanations and course creation
                let response = try await RealAPIService.shared.sendIntelligentAIMessage(message: userMessage)
                
                await MainActor.run {
                    switch response {
                    case .explanation(let text):
                        // Simple explanation - add to chat
                        self?.messages.append(AIMessage(content: text, isFromUser: false))
                    case .courseGenerated(let course):
                        // Course was generated - notify and trigger navigation
                        self?.messages.append(AIMessage(content: "I've created the course \"\(course.title)\" and added it to your library. Taking you there now!", isFromUser: false))
                        self?.generatedCourse = course
                    }
                    self?.isTyping = false
                }
            } catch {
                await MainActor.run {
                    self?.messages.append(AIMessage(content: "I'm having trouble connecting to the AI service right now. Please try again later.", isFromUser: false))
                    self?.isTyping = false
                }
            }
        }
    }
    
    func clearConversation() { 
        messages.removeAll()
        generatedCourse = nil
        addWelcomeMessage()
    }
}

final class AIService: ObservableObject {
    static let shared = AIService(); private init() {}
    @Published var isAvailable = true
    @Published var currentModel = "Lyo-v1"
    func generateResponse(for prompt: String, context: [AIMessage] = []) async throws -> String {
        try await Task.sleep(nanoseconds: 500_000_000)
        return "(Simulated) Response to: \(prompt)"
    }
}

extension AIMessage {
    var messageTypeEnum: AIMessage.MessageType { messageType }
}

// MARK: - Learning Blueprint Types
// LearningBlueprint and BlueprintNode are now defined in CoreTypes.swift

// MARK: - Conversation Types

struct ConversationMessage: Identifiable, Codable {
    let id: UUID
    let senderType: MessageSenderType
    let content: String
    let timestamp: Date
    let metadata: MessageMetadata?
    
    init(
        id: UUID = UUID(),
        senderType: MessageSenderType,
        content: String,
        timestamp: Date = Date(),
        metadata: MessageMetadata? = nil
    ) {
        self.id = id
        self.senderType = senderType
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

enum MessageSenderType: String, Codable {
    case user, ai, system
}

struct MessageMetadata: Codable {
    let sentiment: String?
    let intent: String?
    let confidence: Double?
}

struct SuggestedResponse: Identifiable, Codable {
    let id: UUID
    let text: String
    let relevanceScore: Double
    let category: String
    
    init(
        id: UUID = UUID(),
        text: String,
        relevanceScore: Double = 0.5,
        category: String = "general"
    ) {
        self.id = id
        self.text = text
        self.relevanceScore = relevanceScore
        self.category = category
    }
}

// MARK: - Core Data Models (Canonical Definitions for Module)

/// Environment theme configuration
struct EnvironmentTheme: Codable, Hashable {
    let name: String
    let primaryColor: String
    let secondaryColor: String
    let backgroundColor: String
    let textColor: String
    let accentColor: String
}

// MARK: - Voice & Communication Types

/// Voice activation service (placeholder)
class VoiceActivationService {
    static let shared = VoiceActivationService()
    
    func startListening() async throws {
        // Implementation would start voice recognition
    }
    
    func stopListening() {
        // Implementation would stop voice recognition
    }
}

/// WebSocket service for real-time communication
class LyoWebSocketService {
    static let shared = LyoWebSocketService()
    
    @Published var isConnected = false
    @Published var messages: [WebSocketMessage] = []
    @Published var lastError: Error?
    
    func connect(userId: Int) {
        // Implementation would establish WebSocket connection
        isConnected = true
    }
    
    func disconnect() {
        // Implementation would close WebSocket connection
        isConnected = false
    }
    
    func sendMentorMessage(_ message: String) {
        // Implementation would send message via WebSocket
    }
    
    func sendTypingIndicator(_ isTyping: Bool) {
        // Implementation would send typing indicator
    }
    
    func getConversationMessages() -> [WebSocketMessage] {
        return messages
    }
}

/// WebSocket message structure
struct WebSocketMessage: Codable, Identifiable {
    let id: UUID
    let type: MessageType
    let content: String
    let timestamp: TimeInterval
    
    enum MessageType: String, Codable {
        case mentorMessage
        case mentorResponse
        case systemMessage
    }
}

// MARK: - Avatar View Types

/// Course progress manager
class CourseProgressManager {
    static let shared = CourseProgressManager()
    
    func getProgress(for courseId: String) -> Double {
        // Implementation would return progress 0.0-1.0
        return 0.5
    }
}

/// Immersive avatar engine
class ImmersiveAvatarEngine: ObservableObject {
    static let shared = ImmersiveAvatarEngine()
    
    @Published var currentAvatar: Avatar?
    @Published var isActive = false
    
    func startSession() {
        isActive = true
    }
    
    func endSession() {
        isActive = false
    }
}

/// Avatar customization manager
class AvatarCustomizationManager {
    static let shared = AvatarCustomizationManager()
    
    func getAvailableThemes() -> [EnvironmentTheme] {
        return [
            EnvironmentTheme(
                name: "cosmic",
                primaryColor: "#6366f1",
                secondaryColor: "#8b5cf6",
                backgroundColor: "#0f0f23",
                textColor: "#ffffff",
                accentColor: "#f59e0b"
            )
        ]
    }
}

/// Conversation mode for avatar interactions
enum ConversationMode: String, Codable {
    case learning
    case casual
    case assessment
    case celebration
}

/// Avatar personality types
enum AvatarPersonality: String, Codable {
    case coach
    case mentor
    case friend
    case expert
}

/// Learning context for avatar responses
struct LearningContext: Codable {
    let currentTopic: String?
    let difficulty: String
    let userLevel: String
    let recentProgress: [String]
}

/// Immersive conversation message
struct ImmersiveMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let mood: AvatarMood?
    let actions: [MessageAction]
    let suggestions: [String]
    let actionPerformed: QuickAction?
    
    init(
        id: UUID,
        content: String,
        isFromUser: Bool,
        timestamp: Date,
        mood: AvatarMood? = nil,
        actions: [MessageAction] = [],
        suggestions: [String] = [],
        actionPerformed: QuickAction? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.mood = mood
        self.actions = actions
        self.suggestions = suggestions
        self.actionPerformed = actionPerformed
    }
}

/// Action metadata attached to conversational messages
struct MessageAction: Identifiable, Codable {
    let id: UUID
    let type: MessageActionType
    let title: String
    let iconName: String
}

/// Supported message action types
enum MessageActionType: String, Codable {
    case like
    case share
    case expand
    case clarify
    case practice
}

/// Quick action surfaced in the immersive avatar UI
struct QuickAction: Identifiable, Codable {
    let id: UUID
    let type: QuickActionType
    let title: String
    let description: String
    let iconName: String
}

/// Types of quick actions available to the user
enum QuickActionType: String, Codable {
    case generateCourse
    case quickHelp
    case practiceMode
    case explore
}

/// AI message response payload with actions and suggestions
struct AIMessageActionResponse {
    let content: String
    let actions: [MessageAction]
    let suggestions: [String]
}

/// Avatar mood state for immersive interactions
enum AvatarMood: String, Codable, CaseIterable {
    case friendly
    case excited
    case supportive
    case curious
    case empathetic
    case thoughtful
    case engaged
    
    var displayName: String {
        switch self {
        case .friendly: return "Friendly"
        case .excited: return "Excited"
        case .supportive: return "Supportive"
        case .curious: return "Curious"
        case .empathetic: return "Empathetic"
        case .thoughtful: return "Thoughtful"
        case .engaged: return "Engaged"
        }
    }
}

/// Detected intent of the learner's message
enum UserIntent: String, Codable {
    case seeking_course
    case asking_question
    case sharing_progress
    case expressing_confusion
    case general_conversation
}

/// Emotional tone derived from the learner's message
enum EmotionalTone: String, Codable {
    case positive
    case negative
    case neutral
}

/// Conversation context tracker powering the immersive engine
class ConversationContext {
    private var interactions: [(String, Bool, Date)] = []
    private var topics: [String: Int] = [:]
    private var userPreferences: [String: Double] = [:]
    
    var recentInteractionCount: Int {
        let recentTime = Date().addingTimeInterval(-300)
        return interactions.filter { $0.2 > recentTime }.count
    }
    
    var complexityScore: Double {
        let recentInteractions = interactions.suffix(10)
        let totalLength = recentInteractions.reduce(0) { partialResult, entry in
            partialResult + entry.0.count
        }
        let average = Double(totalLength) / Double(max(recentInteractions.count, 1))
        return min(average / 100.0, 1.0)
    }
    
    func addInteraction(_ content: String, isFromUser: Bool) {
        interactions.append((content, isFromUser, Date()))
        extractTopics(from: content).forEach { topic in
            topics[topic, default: 0] += 1
        }
        if interactions.count > 100 {
            interactions.removeFirst(50)
        }
    }
    
    func addPreference(_ content: String, weight: Double) {
        let key = content.lowercased().prefix(50).trimmingCharacters(in: .whitespacesAndNewlines)
        let identifier = String(key)
        userPreferences[identifier] = (userPreferences[identifier] ?? 0.0) + weight
    }
    
    func extractRecentTopics() -> [String] {
        Array(topics.sorted { $0.value > $1.value }.prefix(5).map { $0.key })
    }
    
    private func extractTopics(from content: String) -> [String] {
        let commonTopics = ["swift", "ios", "programming", "design", "ai", "machine learning", "web development", "course", "learning", "tutorial"]
        return commonTopics.filter { content.lowercased().contains($0) }
    }
}

