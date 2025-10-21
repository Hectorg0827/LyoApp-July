//
//  ProductionWebSocketService.swift
//  LyoApp
//
//  PRODUCTION-ONLY WEBSOCKET SERVICE
//  Real-time notifications, chat, and feed updates from backend.
//  🚫 NO MOCK DATA - PRODUCTION ONLY
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProductionWebSocketService: ObservableObject {
    static let shared = ProductionWebSocketService()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var notifications: [RealTimeNotification] = []
    @Published var unreadCount = 0
    
    // MARK: - Private Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private let wsURL = BackendConfig.environment.webSocketURL
    private var cancellables = Set<AnyCancellable>()
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    private init() {
        print("✅ ProductionWebSocketService initialized")
        print("🌐 WebSocket URL: \(wsURL)")
        print("🚫 Mock WebSocket data: DISABLED")
    }
    
    // MARK: - Connect
    func connect(token: String) {
        guard webSocketTask == nil else {
            print("⚠️ WebSocket already connected")
            return
        }
        
        print("🔌 Connecting to production WebSocket...")
        
        // Create WebSocket URL with authentication
        var components = URLComponents(string: wsURL)
        components?.queryItems = [URLQueryItem(name: "token", value: token)]
        
        guard let url = components?.url else {
            print("❌ Invalid WebSocket URL")
            return
        }
        
        // Create WebSocket task
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        isConnected = true
        reconnectAttempts = 0
        
        print("✅ WebSocket connected")
        
        // Start receiving messages
        receiveMessage()
    }
    
    // MARK: - Disconnect
    func disconnect() {
        print("🔌 Disconnecting WebSocket...")
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    // MARK: - Receive Message
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    
                    // Continue receiving
                    self.receiveMessage()
                    
                case .failure(let error):
                    print("❌ WebSocket error: \(error)")
                    self.handleDisconnect()
                }
            }
        }
    }
    
    // MARK: - Handle Message
    private func handleMessage(_ message: String) {
        print("📨 Received WebSocket message: \(message)")
        
        // Parse JSON message
        guard let data = message.data(using: .utf8) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let wsMessage = try decoder.decode(WebSocketMessage.self, from: data)
            
            switch wsMessage.type {
            case "notification":
                if let notification = wsMessage.notification {
                    handleNotification(notification)
                }
                
            case "feed_update":
                // Notify feed to refresh
                NotificationCenter.default.post(name: .feedUpdateReceived, object: nil)
                
            case "message":
                // Handle chat message
                if let chatMessage = wsMessage.chatMessage {
                    handleChatMessage(chatMessage)
                }
                
            case "ping":
                // Respond with pong
                sendPong()
                
            default:
                print("⚠️ Unknown message type: \(wsMessage.type)")
            }
            
        } catch {
            print("❌ Failed to parse WebSocket message: \(error)")
        }
    }
    
    // MARK: - Handle Notification
    private func handleNotification(_ notification: RealTimeNotification) {
        print("🔔 New notification: \(notification.title)")
        
        // Add to notifications list
        notifications.insert(notification, at: 0)
        
        // Update unread count
        unreadCount += 1
        
        // Show system notification (if permitted)
        showSystemNotification(notification)
        
        // Post notification for other parts of app
        NotificationCenter.default.post(
            name: .newNotificationReceived,
            object: notification
        )
    }
    
    // MARK: - Handle Chat Message
    private func handleChatMessage(_ message: ChatMessage) {
        print("💬 New chat message from: \(message.senderId)")
        
        // Post notification for chat view
        NotificationCenter.default.post(
            name: .newChatMessageReceived,
            object: message
        )
    }
    
    // MARK: - Handle Disconnect
    private func handleDisconnect() {
        isConnected = false
        webSocketTask = nil
        
        // Attempt reconnect
        if reconnectAttempts < maxReconnectAttempts {
            reconnectAttempts += 1
            print("🔄 Reconnecting... (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
            
            // Exponential backoff
            let delay = Double(reconnectAttempts * reconnectAttempts)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let token = APIClient.shared.authToken {
                    self.connect(token: token)
                }
            }
        } else {
            print("❌ Max reconnect attempts reached")
        }
    }
    
    // MARK: - Send Pong
    private func sendPong() {
        let pongMessage = ["type": "pong"]
        if let data = try? JSONEncoder().encode(pongMessage),
           let string = String(data: data, encoding: .utf8) {
            webSocketTask?.send(.string(string)) { error in
                if let error = error {
                    print("❌ Failed to send pong: \(error)")
                }
            }
        }
    }
    
    // MARK: - Show System Notification
    private func showSystemNotification(_ notification: RealTimeNotification) {
        // TODO: Implement system notification with UNUserNotificationCenter
        print("📱 System notification: \(notification.title)")
    }
    
    // MARK: - Mark as Read
    func markAsRead(notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            unreadCount = max(0, unreadCount - 1)
        }
    }
    
    // MARK: - Mark All as Read
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        unreadCount = 0
    }
    
    // MARK: - Clear Notifications
    func clearNotifications() {
        notifications.removeAll()
        unreadCount = 0
    }
}

// MARK: - WebSocket Message Models
struct WebSocketMessage: Codable {
    let type: String
    let notification: RealTimeNotification?
    let chatMessage: ChatMessage?
}

struct RealTimeNotification: Identifiable, Codable {
    let id: String
    let type: String
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let actionUrl: String?
    let senderId: String?
    let senderUsername: String?
    let senderAvatar: String?
}

// Renamed from ChatMessage to avoid conflict with canonical AI ChatMessage
struct RealtimeChatMessage: Identifiable, Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let senderUsername: String
    let senderAvatar: String?
    let text: String
    let timestamp: Date
}

// MARK: - Notification Names
extension Notification.Name {
    static let feedUpdateReceived = Notification.Name("feedUpdateReceived")
    static let newNotificationReceived = Notification.Name("newNotificationReceived")
    static let newChatMessageReceived = Notification.Name("newChatMessageReceived")
}

// MARK: - APIClient Extension for Token Access
extension APIClient {
    var authToken: String? {
        return UserDefaults.standard.string(forKey: "lyo_access_token")
    }
}
