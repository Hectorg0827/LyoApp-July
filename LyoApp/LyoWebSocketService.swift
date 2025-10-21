import Foundation
import Combine

/// WebSocket authentication strategy
private enum WebSocketAuthMethod {
    /// Sends Authorization: Bearer <token> header (preferred)
    case authorizationHeader
    /// Appends ?token=<token> to the URL (fallback)
    case queryParameter(name: String = "token")
}

/// WebSocket service for real-time communication with Lyo AI
@MainActor
class LyoWebSocketService: NSObject, ObservableObject {
    static let shared = LyoWebSocketService()
    
    // MARK: - Configuration
    private var baseURL: String {
        APIEnvironment.current.webSocketBase.absoluteString
    }
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    
    // MARK: - Published State
    @Published var isConnected = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastMessage: WebSocketMessage?
    @Published var messages: [WebSocketMessage] = []
    @Published var lastError: LyoWebSocketError?

    // Optional callback for consumers that prefer a closure over observation
    var onMessageReceived: ((WebSocketMessage) -> Void)?
    
    // MARK: - Avatar Companion State
    @Published var liveTranscript: String = ""
    @Published var isProcessingAudio: Bool = false
    @Published var currentAvatarState: AvatarState = .idle
    @Published var contextualResponse: String = ""
    @Published var isStreaming: Bool = false
    
    // MARK: - Private Properties
    private var userId: String?
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay: TimeInterval = 5.0
    
    // Automatic auth fallback guard
    private var didTryQueryParamFallback = false
    
    // MARK: - Avatar Companion Properties
    private var audioStreamTask: Task<Void, Never>?
    private var contextBuffer: [String] = []
    private let maxContextBufferSize = 10
    private var currentSessionId: String?
    private weak var appState: AppState?
    
    // MARK: - Initialization
    
    override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        self.urlSession = URLSession(configuration: config)
        super.init()
    }
    
    // MARK: - Connection Management
    
    /// Connect using the backend user’s String ID
    func connect(userId: String, appState: AppState? = nil) {
        self.userId = userId
        self.appState = appState
        self.didTryQueryParamFallback = false
        connectInternal(authMethod: .authorizationHeader)
    }
    
    /// Deprecated: integer userId. Prefer connect(userId: String,...)
    func connect(userId: Int, appState: AppState? = nil) {
        connect(userId: String(userId), appState: appState)
    }
    
    private func connectInternal(authMethod: WebSocketAuthMethod) {
        guard let userId = userId else {
            lastError = .invalidURL
            return
        }
        
        var urlString = "\(baseURL)/ai/ws/\(userId)"
        var additionalHeaders: [String: String] = [:]
        
        if let token = TokenStore.shared.getAccessToken(), !token.isEmpty {
            switch authMethod {
            case .authorizationHeader:
                additionalHeaders["Authorization"] = "Bearer \(token)"
            case .queryParameter(let name):
                if var components = URLComponents(string: urlString) {
                    var items = components.queryItems ?? []
                    items.append(URLQueryItem(name: name, value: token))
                    components.queryItems = items
                    urlString = components.url?.absoluteString ?? urlString
                }
            }
        } else {
            print("⚠️ LyoWebSocketService.connect called without access token")
        }
        
        guard let url = URL(string: urlString) else {
            lastError = .invalidURL
            return
        }
        
        disconnect() // Disconnect any existing connection
        
        connectionState = .connecting
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        // Apply headers (Authorization if used)
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start listening for messages
        startListening(currentAuthMethod: authMethod)
        
        // Start ping timer
        startPingTimer()
        
        print("🔌 WebSocket connecting to: \(url) [auth=\(authMethod)]")
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
    
    private func startListening(currentAuthMethod: WebSocketAuthMethod) {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { [weak self] result in
            switch result {
            case .success(let message):
                Task { @MainActor in
                    self?.handleReceivedMessage(message)
                    self?.startListening(currentAuthMethod: currentAuthMethod) // Continue listening
                }
                
            case .failure(let error):
                Task { @MainActor in
                    self?.handleConnectionError(error, lastTriedAuthMethod: currentAuthMethod)
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
            onMessageReceived?(message)
            
            // Handle specific message types
            switch message.type {
            case .connected:
                isConnected = true
                connectionState = .connected
                reconnectAttempts = 0
                currentSessionId = message.metadata?["sessionId"]
                print("✅ WebSocket connected successfully")
                appState?.updateAvatarState(.idle)
                
            case .mentorResponse:
                contextualResponse = message.content
                appState?.updateAvatarState(.speaking)
                if let isStreamingStr = message.metadata?["streaming"],
                   let isStreamingBool = Bool(isStreamingStr) {
                    isStreaming = isStreamingBool
                }
                
            case .transcriptUpdate:
                liveTranscript = message.content
                appState?.updateLiveTranscript(message.content)
                
            case .avatarStateChange:
                if let rawState = AvatarState(rawValue: message.content) {
                    currentAvatarState = rawState
                    appState?.updateAvatarState(rawState)
                }
                
            case .contextualResponse:
                contextualResponse = message.content
                appState?.updateAvatarState(.speaking)
                
            case .speechSynthesis:
                // Handle speech synthesis response if needed
                break
                
            case .audioStream:
                // Handle audio stream response if needed
                break
                
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
        print("📦 Received binary data: \(data.count) bytes")
    }
    
    private func handleConnectionError(_ error: Error, lastTriedAuthMethod: WebSocketAuthMethod) {
        print("❌ WebSocket error: \(error)")
        
        isConnected = false
        connectionState = .disconnected
        
        // If we got an auth-related failure and haven't tried the fallback, retry once with query parameter
        if shouldAttemptAuthFallback(for: error), !didTryQueryParamFallback {
            didTryQueryParamFallback = true
            print("🔁 Retrying WebSocket with token query parameter fallback")
            connectInternal(authMethod: .queryParameter())
            return
        }
        
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
    
    private func shouldAttemptAuthFallback(for error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        // badServerResponse often indicates 401/403 during upgrade, which isn’t directly exposed.
        // We treat it as a candidate for auth fallback.
        return urlError.code == .badServerResponse || urlError.code == .userAuthenticationRequired
    }
    
    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts,
              let userId = userId else { return }
        
        reconnectAttempts += 1
        connectionState = .reconnecting
        
        print("🔄 Attempting to reconnect (\(reconnectAttempts)/\(maxReconnectAttempts))")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                // On reconnect attempts, start with the preferred method again.
                self?.didTryQueryParamFallback = false
                self?.connect(userId: userId, appState: self?.appState)
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
    
    // MARK: - Avatar Companion Methods
    
    /// Send live transcript for contextual processing
    func sendLiveTranscript(_ transcript: String) {
        let message = WebSocketMessage(
            type: .transcriptUpdate,
            content: transcript,
            timestamp: Date().timeIntervalSince1970,
            metadata: ["sessionId": currentSessionId ?? ""]
        )
        
        sendMessage(message)
        liveTranscript = transcript
        appState?.updateLiveTranscript(transcript)
    }
    
    /// Send audio stream data for real-time processing
    func sendAudioStream(_ audioData: Data) {
        guard let webSocketTask = webSocketTask, isConnected else { return }
        
        isProcessingAudio = true
        webSocketTask.send(.data(audioData)) { [weak self] error in
            Task { @MainActor in
                self?.isProcessingAudio = false
                if let error = error {
                    self?.lastError = .sendError
                    print("❌ Failed to send audio stream: \(error)")
                }
            }
        }
    }
    
    /// Send contextual information for avatar response
    func sendContextualRequest(_ context: String, currentScreen: String? = nil) {
        var metadata: [String: String] = ["sessionId": currentSessionId ?? ""]
        if let screen = currentScreen {
            metadata["currentScreen"] = screen
        }
        
        let message = WebSocketMessage(
            type: .contextualResponse,
            content: context,
            timestamp: Date().timeIntervalSince1970,
            metadata: metadata
        )
        
        sendMessage(message)
        addToContextBuffer(context)
    }
    
    /// Update avatar state
    func updateAvatarState(_ state: AvatarState) {
        currentAvatarState = state
        appState?.updateAvatarState(state)
        
        let message = WebSocketMessage(
            type: .avatarStateChange,
            content: state.rawValue,
            timestamp: Date().timeIntervalSince1970,
            metadata: ["sessionId": currentSessionId ?? ""]
        )
        
        sendMessage(message)
    }
    
    /// Request speech synthesis
    func requestSpeechSynthesis(_ text: String) {
        let message = WebSocketMessage(
            type: .speechSynthesis,
            content: text,
            timestamp: Date().timeIntervalSince1970,
            metadata: ["sessionId": currentSessionId ?? ""]
        )
        
        sendMessage(message)
    }
    
    // MARK: - Context Management
    
    private func addToContextBuffer(_ context: String) {
        contextBuffer.append(context)
        if contextBuffer.count > maxContextBufferSize {
            contextBuffer.removeFirst()
        }
    }
    
    /// Get current context for avatar interactions
    func getCurrentContext() -> String {
        return contextBuffer.joined(separator: "\n")
    }
    
    /// Clear context buffer
    func clearContext() {
        contextBuffer.removeAll()
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

enum LyoWebSocketError: Error, LocalizedError {
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
        
        // Avatar Companion specific message types
        case audioStream = "audio_stream"
        case transcriptUpdate = "transcript_update"
        case avatarStateChange = "avatar_state_change"
        case contextualResponse = "contextual_response"
        case speechSynthesis = "speech_synthesis"
    }
}

// MARK: - Extensions

extension AvatarState {
    var rawValue: String {
        switch self {
        case .idle: return "idle"
        case .listening: return "listening"
        case .thinking: return "thinking"
        case .speaking: return "speaking"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "idle": self = .idle
        case "listening": self = .listening
        case "thinking": self = .thinking
        case "speaking": self = .speaking
        default: return nil
        }
    }
}

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
    
    // MARK: - Message Stream
    /// Create an async stream of incoming WebSocket messages for reactive consumption
    func messageStream() async -> AsyncStream<WebSocketMessage> {
        return AsyncStream { continuation in
            // Store the continuation to send messages to it
            self.onMessageReceived = { message in
                continuation.yield(message)
            }
            
            // Clean up when stream is cancelled
            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.onMessageReceived = nil
                }
            }
        }
    }
    
    /// Send a generic message (wrapper for MessengerService)
    func send(message: WebSocketMessage) {
        sendMessage(message)
    }
}

// MARK: - Real Message Management (No Mock Data)

extension LyoWebSocketService {
    /// Clear old messages to manage memory
    func cleanupOldMessages() {
        let oneDayAgo = Date().timeIntervalSince1970 - 86400 // 24 hours
        messages.removeAll { $0.timestamp < oneDayAgo }
    }
    
    /// Get conversation summary for AI context
    func getConversationSummary() -> String {
        let recentMessages = messages.suffix(10) // Last 10 messages
        return recentMessages.map { "\($0.type.rawValue): \($0.content)" }.joined(separator: "\n")
    }
}
