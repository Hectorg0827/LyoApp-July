import Foundation
import Combine

/// Production-ready WebSocket manager for real-time features
@MainActor
class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastMessage: WebSocketMessage?
    @Published var messages: [WebSocketMessage] = []
    
    // MARK: - Private Properties
    private let webSocketClient = WebSocketClient()
    private let authManager = AuthManager()
    private var pingTimer: Timer?
    private let pingInterval: TimeInterval = 30
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case failed
        
        var displayText: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .reconnecting: return "Reconnecting..."
            case .failed: return "Connection Failed"
            }
        }
    }
    
    struct WebSocketMessage: Identifiable {
        let id = UUID()
        let type: String
        let data: [String: Any]
        let timestamp: Date
        
        init(type: String, data: [String: Any] = [:]) {
            self.type = type
            self.data = data
            self.timestamp = Date()
        }
    }
    
    private init() {
        print("🔌 WebSocketManager initialized")
    }
    
    // MARK: - Connection Management
    
    func connect() async {
        guard connectionStatus != .connected && connectionStatus != .connecting else { return }
        
        connectionStatus = .connecting
        print("🔌 Attempting WebSocket connection...")
        
        let wsURL = APIEnvironment.current.webSocketBase.appendingPathComponent("ws")
        
        await webSocketClient.connectWithAuth(url: wsURL, authManager: authManager) { [weak self] result in
            Task { @MainActor in
                await self?.handleWebSocketMessage(result)
            }
        }
        
        // Start ping timer to maintain connection
        startPingTimer()
        
        connectionStatus = .connected
        isConnected = true
        reconnectAttempts = 0
        
        print("✅ WebSocket connected successfully")
        
        // Send initial connection message
        await sendMessage(type: "connection", data: ["status": "connected"])
    }
    
    func disconnect() {
        connectionStatus = .disconnected
        isConnected = false
        
        stopPingTimer()
        webSocketClient.disconnect()
        
        print("🔌 WebSocket disconnected")
    }
    
    // MARK: - Message Handling
    
    private func handleWebSocketMessage(_ result: Result<Data, Error>) async {
        switch result {
        case .success(let data):
            await processMessageData(data)
            
        case .failure(let error):
            print("❌ WebSocket message error: \(error)")
            
            connectionStatus = .failed
            isConnected = false
            
            // Attempt reconnection
            await attemptReconnection()
        }
    }
    
    private func processMessageData(_ data: Data) async {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let messageType = json["type"] as? String else {
                print("⚠️ Invalid WebSocket message format")
                return
            }
            
            let messageData = json["data"] as? [String: Any] ?? [:]
            let message = WebSocketMessage(type: messageType, data: messageData)
            
            // Store message
            messages.append(message)
            lastMessage = message
            
            // Keep only last 100 messages to prevent memory issues
            if messages.count > 100 {
                messages.removeFirst(messages.count - 100)
            }
            
            // Process specific message types
            await handleSpecificMessage(message)
            
        } catch {
            print("❌ Failed to parse WebSocket message: \(error)")
        }
    }
    
    private func handleSpecificMessage(_ message: WebSocketMessage) async {
        switch message.type {
        case "feed_update":
            NotificationCenter.default.post(
                name: .feedUpdate,
                object: message.data
            )
            print("📱 Feed update received")
            
        case "course_progress":
            NotificationCenter.default.post(
                name: .courseProgress,
                object: message.data
            )
            print("📚 Course progress update received")
            
        case "notification":
            NotificationCenter.default.post(
                name: .pushNotification,
                object: message.data
            )
            print("🔔 Push notification received")
            
        case "user_activity":
            NotificationCenter.default.post(
                name: .userActivity,
                object: message.data
            )
            print("👤 User activity update received")
            
        case "live_chat":
            NotificationCenter.default.post(
                name: .liveChatMessage,
                object: message.data
            )
            print("💬 Live chat message received")
            
        case "system_announcement":
            NotificationCenter.default.post(
                name: .systemAnnouncement,
                object: message.data
            )
            print("📢 System announcement received")
            
        default:
            print("🔍 Unknown message type: \(message.type)")
        }
    }
    
    // MARK: - Send Messages
    
    func sendMessage(type: String, data: [String: Any] = [:]) async {
        let message = [
            "type": type,
            "data": data,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            try await webSocketClient.send(text: jsonString)
            print("📤 WebSocket message sent: \(type)")
            
        } catch {
            print("❌ Failed to send WebSocket message: \(error)")
        }
    }
    
    // MARK: - Ping Management
    
    private func startPingTimer() {
        stopPingTimer()
        
        pingTimer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.sendPing()
            }
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() async {
        do {
            try await webSocketClient.ping()
            print("🏓 WebSocket ping sent")
        } catch {
            print("❌ WebSocket ping failed: \(error)")
            
            connectionStatus = .failed
            isConnected = false
            
            await attemptReconnection()
        }
    }
    
    // MARK: - Reconnection Logic
    
    private func attemptReconnection() async {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ Max reconnection attempts reached")
            connectionStatus = .failed
            return
        }
        
        reconnectAttempts += 1
        connectionStatus = .reconnecting
        
        print("🔄 WebSocket reconnection attempt \(reconnectAttempts)/\(maxReconnectAttempts)")
        
        // Exponential backoff
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0)
        
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Attempt to reconnect
        await connect()
    }
    
    // MARK: - Convenience Methods
    
    func sendFeedUpdate(postId: String, action: String) async {
        await sendMessage(type: "feed_update", data: [
            "post_id": postId,
            "action": action
        ])
    }
    
    func sendCourseProgress(courseId: String, progress: Double) async {
        await sendMessage(type: "course_progress", data: [
            "course_id": courseId,
            "progress": progress
        ])
    }
    
    func sendUserActivity(activity: String) async {
        await sendMessage(type: "user_activity", data: [
            "activity": activity,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func sendChatMessage(message: String, channelId: String) async {
        await sendMessage(type: "live_chat", data: [
            "message": message,
            "channel_id": channelId
        ])
    }
    
    // MARK: - Connection Status
    
    func getConnectionStatusColor() -> String {
        switch connectionStatus {
        case .connected:
            return "green"
        case .connecting, .reconnecting:
            return "orange"
        case .disconnected, .failed:
            return "red"
        }
    }
    
    func getLastMessageSummary() -> String {
        guard let lastMessage = lastMessage else { return "No messages" }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        return "\(lastMessage.type.capitalized) at \(timeFormatter.string(from: lastMessage.timestamp))"
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let feedUpdate = Notification.Name("feedUpdate")
    static let courseProgress = Notification.Name("courseProgress")
    static let pushNotification = Notification.Name("pushNotification")
    static let userActivity = Notification.Name("userActivity")
    static let liveChatMessage = Notification.Name("liveChatMessage")
    static let systemAnnouncement = Notification.Name("systemAnnouncement")
}

// MARK: - WebSocket Event Types
enum WebSocketEventType {
    case feedUpdate
    case courseProgress
    case notification
    case userActivity
    case liveChat
    case systemAnnouncement
    case connection
    case custom(String)
    
    var rawValue: String {
        switch self {
        case .feedUpdate: return "feed_update"
        case .courseProgress: return "course_progress"
        case .notification: return "notification"
        case .userActivity: return "user_activity"
        case .liveChat: return "live_chat"
        case .systemAnnouncement: return "system_announcement"
        case .connection: return "connection"
        case .custom(let type): return type
        }
    }
}
