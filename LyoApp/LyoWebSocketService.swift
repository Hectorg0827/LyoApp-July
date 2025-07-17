import Foundation
import Combine

/// WebSocket service for real-time communication with Lyo AI
@MainActor
class LyoWebSocketService: NSObject, ObservableObject {
    static let shared = LyoWebSocketService()
    
    // MARK: - Configuration
    private let baseURL = LyoConfiguration.getWebSocketURL()
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    
    // MARK: - Published State
    @Published var isConnected = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastMessage: WebSocketMessage?
    @Published var messages: [WebSocketMessage] = []
    @Published var lastError: WebSocketError?
    
    // MARK: - Private Properties
    private var userId: Int?
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay: TimeInterval = 5.0
    
    // MARK: - Initialization
    
    override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        self.urlSession = URLSession(configuration: config)
        super.init()
    }
    
    // MARK: - Connection Management
    
    func connect(userId: Int) {
        self.userId = userId
        guard let url = URL(string: "\(baseURL)/ai/ws/\(userId)") else {
            lastError = .invalidURL
            return
        }
        
        disconnect() // Disconnect any existing connection
        
        connectionState = .connecting
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start listening for messages
        startListening()
        
        // Start ping timer
        startPingTimer()
        
        print("🔌 WebSocket connecting to: \(url)")
    }
    
    func disconnect() {
        connectionState = .disconnecting
        
        // Stop timers
        pingTimer?.invalidate()
        pingTimer = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        // Close WebSocket
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        // Update state
        isConnected = false
        connectionState = .disconnected
        
        print("🔌 WebSocket disconnected")
    }
    
    private func startListening() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { [weak self] result in
            switch result {
            case .success(let message):
                Task { @MainActor in
                    self?.handleReceivedMessage(message)
                    self?.startListening() // Continue listening
                }
                
            case .failure(let error):
                Task { @MainActor in
                    self?.handleConnectionError(error)
                }
            }
        }
    }
    
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            handleDataMessage(data)
        @unknown default:
            print("⚠️ Unknown WebSocket message type")
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            messages.append(message)
            lastMessage = message
            
            // Handle specific message types
            switch message.type {
            case .connected:
                isConnected = true
                connectionState = .connected
                reconnectAttempts = 0
                print("✅ WebSocket connected successfully")
                
            case .mentorResponse:
                print("💬 Received mentor response: \(message.content)")
                
            case .error:
                lastError = .messageError(message.content)
                print("❌ WebSocket error: \(message.content)")
                
            case .pong:
                print("🏓 Received pong")
                
            default:
                print("📦 Received message: \(message.type.rawValue)")
            }
            
        } catch {
            print("❌ Failed to decode WebSocket message: \(error)")
            lastError = .decodingError
        }
    }
    
    private func handleDataMessage(_ data: Data) {
        // Handle binary data if needed
        print("📦 Received binary data: \(data.count) bytes")
    }
    
    private func handleConnectionError(_ error: Error) {
        print("❌ WebSocket error: \(error)")
        
        isConnected = false
        connectionState = .disconnected
        
        if let wsError = error as? URLError {
            switch wsError.code {
            case .networkConnectionLost:
                lastError = .connectionClosed
            case .badServerResponse:
                lastError = .protocolError
            default:
                lastError = .connectionError
            }
        } else {
            lastError = .connectionError
        }
        
        // Attempt to reconnect
        attemptReconnect()
    }
    
    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts,
              let userId = userId else { return }
        
        reconnectAttempts += 1
        connectionState = .reconnecting
        
        print("🔄 Attempting to reconnect (\(reconnectAttempts)/\(maxReconnectAttempts))")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.connect(userId: userId)
            }
        }
    }
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendPing()
            }
        }
    }
    
    private func sendPing() {
        let pingMessage = WebSocketMessage(
            type: .ping,
            content: "ping",
            timestamp: Date().timeIntervalSince1970
        )
        
        sendMessage(pingMessage)
    }
    
    // MARK: - Message Sending
    
    func sendMessage(_ message: WebSocketMessage) {
        guard let webSocketTask = webSocketTask,
              isConnected else {
            lastError = .notConnected
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                lastError = .encodingError
                return
            }
            
            webSocketTask.send(.string(jsonString)) { error in
                if let error = error {
                    Task { @MainActor in
                        self.lastError = .sendError
                        print("❌ Failed to send message: \(error)")
                    }
                }
            }
            
        } catch {
            lastError = .encodingError
            print("❌ Failed to encode message: \(error)")
        }
    }
    
    func sendMentorMessage(_ content: String) {
        let message = WebSocketMessage(
            type: .mentorMessage,
            content: content,
            timestamp: Date().timeIntervalSince1970
        )
        
        sendMessage(message)
    }
    
    func sendTypingIndicator(_ isTyping: Bool) {
        let message = WebSocketMessage(
            type: .typing,
            content: isTyping ? "typing" : "stopped",
            timestamp: Date().timeIntervalSince1970
        )
        
        sendMessage(message)
    }
    
    // MARK: - Utility Methods
    
    func clearMessages() {
        messages.removeAll()
        lastMessage = nil
    }
    
    func clearError() {
        lastError = nil
    }
}

// MARK: - Supporting Types

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case disconnecting
}

enum WebSocketError: Error, LocalizedError {
    case invalidURL
    case notConnected
    case connectionError
    case connectionClosed
    case protocolError
    case encodingError
    case decodingError
    case sendError
    case messageError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .notConnected:
            return "WebSocket not connected"
        case .connectionError:
            return "Connection error"
        case .connectionClosed:
            return "Connection closed"
        case .protocolError:
            return "Protocol error"
        case .encodingError:
            return "Message encoding error"
        case .decodingError:
            return "Message decoding error"
        case .sendError:
            return "Failed to send message"
        case .messageError(let message):
            return "Message error: \(message)"
        }
    }
}

struct WebSocketMessage: Codable, Identifiable {
    let id: UUID
    let type: MessageType
    let content: String
    let timestamp: TimeInterval
    let metadata: [String: String]?
    
    init(type: MessageType, content: String, timestamp: TimeInterval, metadata: [String: String]? = nil) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
    }
    
    enum MessageType: String, Codable {
        case ping = "ping"
        case pong = "pong"
        case connected = "connected"
        case mentorMessage = "mentor_message"
        case mentorResponse = "mentor_response"
        case typing = "typing"
        case error = "error"
        case taskStatus = "task_status"
        case courseGenerated = "course_generated"
        case lessonContent = "lesson_content"
    }
}

// MARK: - Extensions

extension LyoWebSocketService {
    /// Get messages of a specific type
    func getMessages(of type: WebSocketMessage.MessageType) -> [WebSocketMessage] {
        return messages.filter { $0.type == type }
    }
    
    /// Get conversation messages (mentor messages and responses)
    func getConversationMessages() -> [WebSocketMessage] {
        return messages.filter { 
            $0.type == .mentorMessage || $0.type == .mentorResponse 
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Check if currently connected
    var isCurrentlyConnected: Bool {
        return isConnected && connectionState == .connected
    }
    
    /// Get formatted timestamp for a message
    func formattedTimestamp(for message: WebSocketMessage) -> String {
        let date = Date(timeIntervalSince1970: message.timestamp)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Mock Data for Testing

extension LyoWebSocketService {
    /// Add mock messages for testing
    func addMockMessages() {
        let mockMessages = [
            WebSocketMessage(
                type: .mentorResponse,
                content: "Hello! I'm Lyo, your AI learning companion. What would you like to learn today?",
                timestamp: Date().timeIntervalSince1970 - 300
            ),
            WebSocketMessage(
                type: .mentorMessage,
                content: "I want to learn about machine learning",
                timestamp: Date().timeIntervalSince1970 - 250
            ),
            WebSocketMessage(
                type: .mentorResponse,
                content: "Great choice! Machine learning is fascinating. Let me help you break this down into manageable topics. Are you interested in the theoretical foundations or practical applications?",
                timestamp: Date().timeIntervalSince1970 - 200
            )
        ]
        
        messages.append(contentsOf: mockMessages)
        lastMessage = mockMessages.last
    }
}