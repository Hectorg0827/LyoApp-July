import Foundation
import SwiftUI
import Combine

// MARK: - Messenger Service (Real Backend + WebSocket)
/// Handles all messaging operations with real backend and WebSocket support
@MainActor
final class MessengerService: ObservableObject {
    static let shared = MessengerService()
    
    // MARK: - Published Properties
    @Published var conversations: [MessengerConversation] = []
    @Published var activeConversation: MessengerConversation?
    @Published var messages: [MessengerMessage] = []
    @Published var isLoading = false
    @Published var isConnected = false
    @Published var typingUsers: Set<String> = []
    @Published var error: MessengerServiceError?
    
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private var webSocketService: LyoWebSocketService?
    private var cancellables = Set<AnyCancellable>()
    
    // Backend endpoints
    private let conversationsEndpoint = "/api/v1/messenger/conversations"
    private let messagesEndpoint = "/api/v1/messenger/conversations/{conversationId}/messages"
    private let sendMessageEndpoint = "/api/v1/messenger/conversations/{conversationId}/messages"
    private let markReadEndpoint = "/api/v1/messenger/conversations/{conversationId}/read"
    
    // MARK: - Initialization
    private init() {
        print("💬 MessengerService: Initialized with REAL backend + WebSocket")
        setupWebSocket()
    }
    
    // MARK: - WebSocket Setup
    private func setupWebSocket() {
        webSocketService = LyoWebSocketService.shared
        
        // Listen for WebSocket connection status
        webSocketService?.$isConnected
            .assign(to: &$isConnected)
        
        // Listen for incoming messages
        Task {
            await listenForMessages()
        }
    }
    
    private func listenForMessages() async {
        guard let webSocketService = webSocketService else { return }
        
        for await message in await webSocketService.messageStream() {
            handleWebSocketMessage(message)
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        switch message.type {
        case "new_message":
            if let messageData = message.data as? [String: Any],
               let newMessage = parseMessage(from: messageData) {
                handleNewMessage(newMessage)
            }
            
        case "typing_indicator":
            if let data = message.data as? [String: Any],
               let userId = data["userId"] as? String,
               let isTyping = data["isTyping"] as? Bool {
                handleTypingIndicator(userId: userId, isTyping: isTyping)
            }
            
        case "message_read":
            if let data = message.data as? [String: Any],
               let messageId = data["messageId"] as? String {
                markMessageAsRead(messageId: messageId)
            }
            
        case "conversation_updated":
            Task {
                await loadConversations()
            }
            
        default:
            print("💬 MessengerService: Unknown WebSocket message type: \(message.type)")
        }
    }
    
    // MARK: - Conversations
    /// Load all conversations
    func loadConversations() async {
        // Check authentication first
        guard TokenStore.shared.loadTokens() != nil else {
            error = .unauthorized
            print("❌ MessengerService: User not authenticated")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("💬 MessengerService: Loading conversations...")
            
            let response: ConversationsResponse = try await apiClient.request(
                endpoint: conversationsEndpoint,
                method: .GET
            )
            
            conversations = response.conversations.map { convertToConversation($0) }
            
            print("✅ MessengerService: Loaded \(conversations.count) conversations")
            
        } catch let apiError as APIClientError {
            error = .apiError(apiError)
            print("❌ MessengerService: Failed to load conversations - \(apiError)")
        } catch {
            self.error = .unknown(error.localizedDescription)
            print("❌ MessengerService: Unknown error - \(error)")
        }
    }
    
    /// Select a conversation and load its messages
    func selectConversation(_ conversation: MessengerConversation) async {
        activeConversation = conversation
        await loadMessages(for: conversation.id)
        await markConversationAsRead(conversation.id)
    }
    
    // MARK: - Messages
    /// Load messages for a conversation
    func loadMessages(for conversationId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let endpoint = messagesEndpoint.replacingOccurrences(of: "{conversationId}", with: conversationId)
            
            print("💬 MessengerService: Loading messages for conversation \(conversationId)...")
            
            let response: MessagesResponse = try await apiClient.request(
                endpoint: endpoint,
                method: .GET
            )
            
            messages = response.messages.map { convertToMessage($0) }
            
            print("✅ MessengerService: Loaded \(messages.count) messages")
            
        } catch let apiError as APIClientError {
            error = .apiError(apiError)
            print("❌ MessengerService: Failed to load messages - \(apiError)")
        } catch {
            self.error = .unknown(error.localizedDescription)
        }
    }
    
    /// Send a text message
    func sendMessage(conversationId: String, content: String, recipientId: String) async -> Bool {
        do {
            let endpoint = sendMessageEndpoint.replacingOccurrences(of: "{conversationId}", with: conversationId)
            
            let response: APIMessage = try await apiClient.request(
                endpoint: endpoint,
                method: .POST,
                body: [
                    "content": content,
                    "recipientId": recipientId,
                    "messageType": "text"
                ]
            )
            
            let newMessage = convertToMessage(response)
            messages.append(newMessage)
            
            // Update conversation's last message
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index].lastMessage = newMessage
                conversations[index].updatedAt = Date()
            }
            
            print("✅ MessengerService: Message sent")
            return true
            
        } catch {
            print("❌ MessengerService: Failed to send message - \(error)")
            return false
        }
    }
    
    /// Send a voice message
    func sendVoiceMessage(conversationId: String, audioURL: URL, duration: TimeInterval, recipientId: String) async -> Bool {
        do {
            // First, upload the audio file
            let uploadEndpoint = "/api/v1/media/upload"
            let mediaResponse: MediaUploadResponse = try await apiClient.uploadFile(
                endpoint: uploadEndpoint,
                fileURL: audioURL,
                mimeType: "audio/m4a",
                fieldName: "audio"
            )
            
            // Then send the message with the media URL
            let endpoint = sendMessageEndpoint.replacingOccurrences(of: "{conversationId}", with: conversationId)
            
            let response: APIMessage = try await apiClient.request(
                endpoint: endpoint,
                method: .POST,
                body: [
                    "content": "Voice Message",
                    "recipientId": recipientId,
                    "messageType": "voice",
                    "mediaUrl": mediaResponse.url,
                    "voiceDuration": duration
                ]
            )
            
            let newMessage = convertToMessage(response)
            messages.append(newMessage)
            
            print("✅ MessengerService: Voice message sent")
            return true
            
        } catch {
            print("❌ MessengerService: Failed to send voice message - \(error)")
            return false
        }
    }
    
    /// Send typing indicator
    func sendTypingIndicator(conversationId: String, isTyping: Bool) {
        webSocketService?.send(message: WebSocketMessage(
            type: "typing_indicator",
            data: [
                "conversationId": conversationId,
                "isTyping": isTyping
            ]
        ))
    }
    
    /// Mark conversation as read
    func markConversationAsRead(_ conversationId: String) async {
        do {
            let endpoint = markReadEndpoint.replacingOccurrences(of: "{conversationId}", with: conversationId)
            
            let _: EmptyResponse = try await apiClient.request(
                endpoint: endpoint,
                method: .POST
            )
            
            // Update local state
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index].unreadCount = 0
            }
            
            print("✅ MessengerService: Conversation marked as read")
            
        } catch {
            print("❌ MessengerService: Failed to mark as read - \(error)")
        }
    }
    
    // MARK: - Real-time Updates
    private func handleNewMessage(_ message: MessengerMessage) {
        // Add to messages if it's for the active conversation
        if message.conversationId == activeConversation?.id {
            messages.append(message)
        }
        
        // Update conversation's last message
        if let index = conversations.firstIndex(where: { $0.id == message.conversationId }) {
            conversations[index].lastMessage = message
            conversations[index].updatedAt = Date()
            
            // Increment unread count if not active conversation
            if message.conversationId != activeConversation?.id {
                conversations[index].unreadCount += 1
            }
        }
        
        print("💬 MessengerService: New message received")
    }
    
    private func handleTypingIndicator(userId: String, isTyping: Bool) {
        if isTyping {
            typingUsers.insert(userId)
        } else {
            typingUsers.remove(userId)
        }
    }
    
    private func markMessageAsRead(messageId: String) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index].isRead = true
        }
    }
    
    // MARK: - Helper Methods
    private func convertToConversation(_ apiConversation: APIConversation) -> MessengerConversation {
        let participants = apiConversation.participants.map { participantId in
            // In a real app, you'd fetch user details
            User(
                id: UUID(uuidString: participantId) ?? UUID(),
                username: "User",
                email: "\(participantId)@lyo.app",
                fullName: "User"
            )
        }
        
        let lastMessage = apiConversation.lastMessage.map { convertToMessage($0) }
        
        return MessengerConversation(
            id: apiConversation.id,
            participants: participants,
            lastMessage: lastMessage,
            updatedAt: ISO8601DateFormatter().date(from: apiConversation.updatedAt) ?? Date(),
            isGroup: apiConversation.isGroup,
            name: apiConversation.name,
            unreadCount: apiConversation.unreadCount
        )
    }
    
    private func convertToMessage(_ apiMessage: APIMessage) -> MessengerMessage {
        return MessengerMessage(
            id: apiMessage.id,
            conversationId: apiMessage.conversationId,
            senderId: apiMessage.senderId,
            content: apiMessage.content,
            messageType: MessageType(rawValue: apiMessage.messageType) ?? .text,
            timestamp: ISO8601DateFormatter().date(from: apiMessage.createdAt) ?? Date(),
            isRead: apiMessage.isRead,
            reactions: [],
            replyTo: apiMessage.replyTo,
            mediaUrl: apiMessage.mediaUrl,
            voiceDuration: apiMessage.voiceDuration,
            isEdited: apiMessage.isEdited,
            deletedAt: apiMessage.deletedAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        )
    }
    
    private func parseMessage(from data: [String: Any]) -> MessengerMessage? {
        // Parse WebSocket message data
        guard let id = data["id"] as? String,
              let conversationId = data["conversationId"] as? String,
              let senderId = data["senderId"] as? String,
              let content = data["content"] as? String else {
            return nil
        }
        
        return MessengerMessage(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            messageType: .text,
            timestamp: Date(),
            isRead: false,
            reactions: [],
            replyTo: nil,
            mediaUrl: nil,
            voiceDuration: nil,
            isEdited: false,
            deletedAt: nil
        )
    }
}

// MARK: - Service Errors
enum MessengerServiceError: LocalizedError {
    case apiError(APIClientError)
    case webSocketDisconnected
    case invalidData
    case unauthorized
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .apiError(let error):
            return error.errorDescription
        case .webSocketDisconnected:
            return "Connection lost. Please check your internet connection."
        case .invalidData:
            return "Invalid data received from server"
        case .unauthorized:
            return "Please log in to access messenger"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - API Response Models
struct ConversationsResponse: Codable {
    let conversations: [APIConversation]
}

struct APIConversation: Codable {
    let id: String
    let participants: [String]
    let lastMessage: APIMessage?
    let updatedAt: String
    let isGroup: Bool
    let name: String?
    let unreadCount: Int
}

struct MessagesResponse: Codable {
    let messages: [APIMessage]
}

struct APIMessage: Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let messageType: String
    let createdAt: String
    let isRead: Bool
    let replyTo: String?
    let mediaUrl: String?
    let voiceDuration: TimeInterval?
    let isEdited: Bool
    let deletedAt: String?
}

struct MediaUploadResponse: Codable {
    let url: String
    let mimeType: String
    let size: Int
}

struct EmptyResponse: Codable {}

// MARK: - WebSocket Message Structure
struct WebSocketMessage: Codable {
    let type: String
    let data: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    init(type: String, data: [String: Any]? = nil) {
        self.type = type
        self.data = data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        data = try? container.decode([String: Any].self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        if let data = data {
            try container.encode(data, forKey: .data)
        }
    }
}
