import Foundation
import Network
import OSLog
import SwiftUI

// MARK: - WebSocket Manager
@MainActor
class WebSocketManager: NSObject, ObservableObject {
    static let shared = WebSocketManager()
    
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastMessage: WebSocketMessage?
    @Published var unreadCount = 0
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private let logger = Logger(subsystem: "com.lyo.app", category: "WebSocket")
    
    // Configuration
    private let baseURL = "wss://lyo-backend-830162750094.us-central1.run.app"
    private let reconnectDelay: TimeInterval = 5.0
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    // Message handling
    private var messageHandlers: [String: (WebSocketMessage) -> Void] = [:]
    private var authToken: String?
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case failed(Error)
        
        var description: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .reconnecting: return "Reconnecting..."
            case .failed(let error): return "Failed: \(error.localizedDescription)"
            }
        }
        
        var color: Color {
            switch self {
            case .connected: return .green
            case .connecting, .reconnecting: return .orange
            case .disconnected: return .gray
            case .failed: return .red
            }
        }
    }
    
    override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        super.init()
        
        logger.info("🔌 WebSocketManager initialized")
    }
    
    // MARK: - Connection Management
    func connect(authToken: String? = nil) {
        self.authToken = authToken
        
        guard connectionStatus != .connecting else {
            logger.info("🔌 Already connecting to WebSocket")
            return
        }
        
        connectionStatus = .connecting
        
        guard let url = buildWebSocketURL() else {
            logger.error("❌ Invalid WebSocket URL")
            connectionStatus = .failed(WebSocketError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        
        // Add authentication if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        logger.info("🔌 Connecting to WebSocket: \(url)")
        
        // Start listening for messages
        startListening()
        
        // Send ping to establish connection
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await sendPing()
        }
    }
    
    func disconnect() {
        logger.info("🔌 Disconnecting WebSocket")
        
        webSocketTask?.cancel(with: .goingAway, reason: "User initiated disconnect".data(using: .utf8))
        webSocketTask = nil
        
        connectionStatus = .disconnected
        isConnected = false
        reconnectAttempts = 0
    }
    
    private func buildWebSocketURL() -> URL? {
        var components = URLComponents(string: "\(baseURL)/ws")
        
        // Add query parameters for authentication or room joining
        var queryItems: [URLQueryItem] = []
        
        // Get auth token from secure storage
        if let token = SecureTokenManager.shared.getAccessToken() {
            queryItems.append(URLQueryItem(name: "auth", value: token))
        }
        
        // Add device identification
        let deviceId = SecureTokenManager.shared.getDeviceId()
        queryItems.append(URLQueryItem(name: "device_id", value: deviceId))
        
        // Add app information
        queryItems.append(URLQueryItem(name: "client", value: "ios"))
        queryItems.append(URLQueryItem(name: "version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"))
        queryItems.append(URLQueryItem(name: "build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))
        
        // Add user ID if available
        if let userId = SecureTokenManager.shared.getUserId() {
            queryItems.append(URLQueryItem(name: "user_id", value: userId))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    // MARK: - Message Handling
    private func startListening() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { [weak self] result in
            Task { @MainActor in
                await self?.handleMessage(result)
            }
        }
    }
    
    private func handleMessage(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
        switch result {
        case .success(let message):
            processMessage(message)
            // Continue listening
            startListening()
            
        case .failure(let error):
            logger.error("❌ WebSocket receive error: \(error.localizedDescription)")
            handleConnectionError(error)
        }
    }
    
    private func processMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            logger.info("📨 Received WebSocket message: \(text)")
            
            if let data = text.data(using: .utf8),
               let socketMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                
                lastMessage = socketMessage
                
                // Handle different message types
                switch socketMessage.type {
                case .ping:
                    sendPong()
                case .pong:
                    markConnected()
                case .message:
                    handleChatMessage(socketMessage)
                case .notification:
                    handleNotification(socketMessage)
                case .userStatus:
                    handleUserStatus(socketMessage)
                case .typing:
                    handleTypingIndicator(socketMessage)
                case .error:
                    handleError(socketMessage)
                }
                
                // Call registered handlers
                if let handler = messageHandlers[socketMessage.type.rawValue] {
                    handler(socketMessage)
                }
            }
            
        case .data(let data):
            logger.info("📨 Received binary WebSocket data: \(data.count) bytes")
            // Handle binary data if needed
            
        @unknown default:
            logger.warning("⚠️ Unknown WebSocket message type")
        }
    }
    
    private func markConnected() {
        if !isConnected {
            isConnected = true
            connectionStatus = .connected
            reconnectAttempts = 0
            logger.info("✅ WebSocket connection established")
        }
    }
    
    // MARK: - Message Type Handlers
    private func handleChatMessage(_ message: WebSocketMessage) {
        unreadCount += 1
        // Notify UI about new message
        NotificationCenter.default.post(name: .newChatMessage, object: message)
    }
    
    private func handleNotification(_ message: WebSocketMessage) {
        // Handle push notifications
        NotificationCenter.default.post(name: .newNotification, object: message)
    }
    
    private func handleUserStatus(_ message: WebSocketMessage) {
        // Handle user online/offline status
        NotificationCenter.default.post(name: .userStatusChanged, object: message)
    }
    
    private func handleTypingIndicator(_ message: WebSocketMessage) {
        // Handle typing indicators
        NotificationCenter.default.post(name: .typingIndicator, object: message)
    }
    
    private func handleError(_ message: WebSocketMessage) {
        logger.error("🚨 WebSocket error message: \(message.data ?? [:])")
    }
    
    // MARK: - Send Messages
    func sendMessage(_ message: WebSocketMessage) async {
        guard isConnected else {
            logger.warning("⚠️ Attempting to send message while disconnected")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let text = String(data: data, encoding: .utf8) ?? ""
            
            try await webSocketTask?.send(.string(text))
            logger.info("📤 Sent WebSocket message: \(message.type.rawValue)")
            
        } catch {
            logger.error("❌ Failed to send WebSocket message: \(error.localizedDescription)")
        }
    }
    
    func sendChatMessage(_ content: String, to recipientId: String) async {
        let message = WebSocketMessage(
            type: .message,
            data: [
                "content": content,
                "recipientId": recipientId,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        await sendMessage(message)
    }
    
    func sendTypingIndicator(_ isTyping: Bool, to recipientId: String) async {
        let message = WebSocketMessage(
            type: .typing,
            data: [
                "isTyping": isTyping,
                "recipientId": recipientId
            ]
        )
        
        await sendMessage(message)
    }
    
    private func sendPing() async {
        let ping = WebSocketMessage(type: .ping, data: [:])
        await sendMessage(ping)
    }
    
    private func sendPong() {
        Task {
            let pong = WebSocketMessage(type: .pong, data: [:])
            await sendMessage(pong)
        }
    }
    
    // MARK: - Error Handling & Reconnection
    private func handleConnectionError(_ error: Error) {
        connectionStatus = .failed(error)
        isConnected = false
        
        // Attempt reconnection if not max attempts
        if reconnectAttempts < maxReconnectAttempts {
            reconnectAttempts += 1
            connectionStatus = .reconnecting
            
            logger.info("🔄 Attempting reconnection (\(reconnectAttempts)/\(maxReconnectAttempts))")
            
            Task {
                try? await Task.sleep(nanoseconds: UInt64(reconnectDelay * 1_000_000_000))
                connect(authToken: authToken)
            }
        } else {
            logger.error("❌ Max reconnection attempts reached")
            connectionStatus = .failed(WebSocketError.maxReconnectAttemptsReached)
        }
    }
    
    // MARK: - Message Handler Registration
    func registerMessageHandler(for type: String, handler: @escaping (WebSocketMessage) -> Void) {
        messageHandlers[type] = handler
    }
    
    func unregisterMessageHandler(for type: String) {
        messageHandlers.removeValue(forKey: type)
    }
    
    // MARK: - Utility
    func resetUnreadCount() {
        unreadCount = 0
    }
    
    deinit {
        disconnect()
    }
}

// MARK: - WebSocket Message Model
struct WebSocketMessage: Codable {
    let type: MessageType
    let data: [String: Any]?
    let timestamp: String?
    let id: String
    
    init(type: MessageType, data: [String: Any]? = nil, timestamp: String? = nil) {
        self.type = type
        self.data = data
        self.timestamp = timestamp ?? ISO8601DateFormatter().string(from: Date())
        self.id = UUID().uuidString
    }
    
    enum MessageType: String, Codable {
        case ping = "ping"
        case pong = "pong"
        case message = "message"
        case notification = "notification"
        case userStatus = "user_status"
        case typing = "typing"
        case error = "error"
    }
    
    // Custom encoding/decoding to handle [String: Any]
    enum CodingKeys: String, CodingKey {
        case type, data, timestamp, id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(MessageType.self, forKey: .type)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        id = try container.decode(String.self, forKey: .id)
        
        // Decode data as generic dictionary
        if container.contains(.data) {
            let dataContainer = try container.nestedContainer(keyedBy: GenericCodingKey.self, forKey: .data)
            var dataDict: [String: Any] = [:]
            
            for key in dataContainer.allKeys {
                if let value = try? dataContainer.decode(String.self, forKey: key) {
                    dataDict[key.stringValue] = value
                } else if let value = try? dataContainer.decode(Bool.self, forKey: key) {
                    dataDict[key.stringValue] = value
                } else if let value = try? dataContainer.decode(Int.self, forKey: key) {
                    dataDict[key.stringValue] = value
                }
            }
            
            data = dataDict
        } else {
            data = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encode(id, forKey: .id)
        
        if let data = data {
            var dataContainer = container.nestedContainer(keyedBy: GenericCodingKey.self, forKey: .data)
            
            for (key, value) in data {
                let codingKey = GenericCodingKey(stringValue: key)!
                
                if let stringValue = value as? String {
                    try dataContainer.encode(stringValue, forKey: codingKey)
                } else if let boolValue = value as? Bool {
                    try dataContainer.encode(boolValue, forKey: codingKey)
                } else if let intValue = value as? Int {
                    try dataContainer.encode(intValue, forKey: codingKey)
                }
            }
        }
    }
}

// MARK: - Generic Coding Key
private struct GenericCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - WebSocket Errors
enum WebSocketError: LocalizedError {
    case invalidURL
    case maxReconnectAttemptsReached
    case connectionClosed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .maxReconnectAttemptsReached:
            return "Maximum reconnection attempts reached"
        case .connectionClosed:
            return "WebSocket connection was closed"
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let newChatMessage = Notification.Name("newChatMessage")
    static let newNotification = Notification.Name("newNotification")
    static let userStatusChanged = Notification.Name("userStatusChanged")
    static let typingIndicator = Notification.Name("typingIndicator")
}

// MARK: - WebSocket Status View
struct WebSocketStatusView: View {
    @ObservedObject var webSocketManager = WebSocketManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(webSocketManager.connectionStatus.color)
                .frame(width: 8, height: 8)
            
            Text(webSocketManager.connectionStatus.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}