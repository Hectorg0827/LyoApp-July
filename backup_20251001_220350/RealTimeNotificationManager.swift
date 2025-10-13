import Foundation
import SwiftUI
import UserNotifications
import OSLog

// MARK: - Real-time Notification Manager
@MainActor
final class RealTimeNotificationManager: NSObject, ObservableObject {
    static let shared = RealTimeNotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount = 0
    @Published var isEnabled = false
    
    private let logger = Logger(subsystem: "com.lyo.app", category: "RealTimeNotifications")
    private let webSocketManager = WebSocketManager.shared
    private var notificationHandlers: [String: (AppNotification) -> Void] = [:]
    
    // Notification types
    enum NotificationType: String, CaseIterable {
        case message = "message"
        case like = "like"
        case comment = "comment"
        case follow = "follow"
        case mention = "mention"
        case courseUpdate = "course_update"
        case achievement = "achievement"
        case system = "system"
        
        var icon: String {
            switch self {
            case .message: return "message.fill"
            case .like: return "heart.fill"
            case .comment: return "text.bubble.fill"
            case .follow: return "person.badge.plus.fill"
            case .mention: return "at.badge.plus"
            case .courseUpdate: return "book.fill"
            case .achievement: return "trophy.fill"
            case .system: return "gear.badge"
            }
        }
        
        var color: Color {
            switch self {
            case .message: return .blue
            case .like: return .red
            case .comment: return .green
            case .follow: return .purple
            case .mention: return .orange
            case .courseUpdate: return .indigo
            case .achievement: return .yellow
            case .system: return .gray
            }
        }
    }
    
    struct AppNotification: Identifiable, Codable {
        let id: String
        let type: NotificationType
        let title: String
        let body: String
        let data: [String: String]
        let timestamp: Date
        let isRead: Bool
        let priority: Priority
        
        enum Priority: String, Codable {
            case low = "low"
            case normal = "normal"
            case high = "high"
            case urgent = "urgent"
        }
        
        init(id: String = UUID().uuidString, 
             type: NotificationType, 
             title: String, 
             body: String, 
             data: [String: String] = [:], 
             timestamp: Date = Date(), 
             isRead: Bool = false, 
             priority: Priority = .normal) {
            self.id = id
            self.type = type
            self.title = title
            self.body = body
            self.data = data
            self.timestamp = timestamp
            self.isRead = isRead
            self.priority = priority
        }
    }
    
    override init() {
        super.init()
        setupWebSocketIntegration()
        loadStoredNotifications()
        logger.info("📢 RealTimeNotificationManager initialized")
    }
    
    // MARK: - Permission Management
    
    func requestPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            if granted {
                logger.info("✅ Notification permissions granted")
                isEnabled = true
                
                // Register for remote notifications
                await UIApplication.shared.registerForRemoteNotifications()
            } else {
                logger.warning("❌ Notification permissions denied")
                isEnabled = false
            }
            
            return granted
        } catch {
            logger.error("❌ Failed to request notification permissions: \(error)")
            return false
        }
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        isEnabled = settings.authorizationStatus == .authorized
        return settings.authorizationStatus
    }
    
    // MARK: - WebSocket Integration
    
    private func setupWebSocketIntegration() {
        // Register for WebSocket notifications
        webSocketManager.registerMessageHandler(for: NotificationType.message.rawValue) { [weak self] message in
            Task { @MainActor in
                self?.handleWebSocketNotification(message)
            }
        }
        
        // Monitor WebSocket connection status
        NotificationCenter.default.addObserver(
            forName: .newNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let message = notification.object as? WebSocketMessage {
                self?.handleWebSocketNotification(message)
            }
        }
    }
    
    private func handleWebSocketNotification(_ message: WebSocketMessage) {
        guard let data = message.data else { return }
        
        // Extract notification information
        let title = data["title"] as? String ?? "New Notification"
        let body = data["body"] as? String ?? ""
        let typeString = data["type"] as? String ?? "system"
        let type = NotificationType(rawValue: typeString) ?? .system
        let priority = Priority(rawValue: data["priority"] as? String ?? "normal") ?? .normal
        
        let appNotification = AppNotification(
            id: message.id,
            type: type,
            title: title,
            body: body,
            data: data.compactMapValues { $0 as? String },
            timestamp: Date(),
            isRead: false,
            priority: priority
        )
        
        addNotification(appNotification)
    }
    
    // MARK: - Notification Management
    
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        unreadCount += notification.isRead ? 0 : 1
        
        // Limit stored notifications
        if notifications.count > 100 {
            notifications = Array(notifications.prefix(100))
        }
        
        // Save to storage
        saveNotifications()
        
        // Show local notification if app is in background
        if UIApplication.shared.applicationState != .active {
            showLocalNotification(notification)
        }
        
        // Call registered handlers
        if let handler = notificationHandlers[notification.type.rawValue] {
            handler(notification)
        }
        
        logger.info("📢 Added notification: \(notification.type.rawValue) - \(notification.title)")
    }
    
    func markAsRead(_ notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            let notification = notifications[index]
            if !notification.isRead {
                notifications[index] = AppNotification(
                    id: notification.id,
                    type: notification.type,
                    title: notification.title,
                    body: notification.body,
                    data: notification.data,
                    timestamp: notification.timestamp,
                    isRead: true,
                    priority: notification.priority
                )
                unreadCount = max(0, unreadCount - 1)
                saveNotifications()
            }
        }
    }
    
    func markAllAsRead() {
        notifications = notifications.map { notification in
            AppNotification(
                id: notification.id,
                type: notification.type,
                title: notification.title,
                body: notification.body,
                data: notification.data,
                timestamp: notification.timestamp,
                isRead: true,
                priority: notification.priority
            )
        }
        unreadCount = 0
        saveNotifications()
    }
    
    func clearNotifications() {
        notifications.removeAll()
        unreadCount = 0
        saveNotifications()
    }
    
    func deleteNotification(_ notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            let notification = notifications[index]
            notifications.remove(at: index)
            
            if !notification.isRead {
                unreadCount = max(0, unreadCount - 1)
            }
            
            saveNotifications()
        }
    }
    
    // MARK: - Local Notifications
    
    private func showLocalNotification(_ notification: AppNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.badge = NSNumber(value: unreadCount)
        
        // Add custom data
        var userInfo: [String: Any] = notification.data
        userInfo["notification_id"] = notification.id
        userInfo["type"] = notification.type.rawValue
        content.userInfo = userInfo
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("❌ Failed to schedule local notification: \(error)")
            }
        }
    }
    
    // MARK: - Notification Handlers
    
    func registerNotificationHandler(for type: NotificationType, handler: @escaping (AppNotification) -> Void) {
        notificationHandlers[type.rawValue] = handler
    }
    
    func unregisterNotificationHandler(for type: NotificationType) {
        notificationHandlers.removeValue(forKey: type.rawValue)
    }
    
    // MARK: - Persistence
    
    private func saveNotifications() {
        do {
            let data = try JSONEncoder().encode(notifications)
            UserDefaults.standard.set(data, forKey: "stored_notifications")
        } catch {
            logger.error("❌ Failed to save notifications: \(error)")
        }
    }
    
    private func loadStoredNotifications() {
        guard let data = UserDefaults.standard.data(forKey: "stored_notifications") else { return }
        
        do {
            notifications = try JSONDecoder().decode([AppNotification].self, from: data)
            unreadCount = notifications.filter { !$0.isRead }.count
            logger.info("📢 Loaded \(notifications.count) stored notifications")
        } catch {
            logger.error("❌ Failed to load stored notifications: \(error)")
            notifications = []
            unreadCount = 0
        }
    }
    
    // MARK: - Mock Notifications (for testing)
    
    func addMockNotifications() {
        let mockNotifications = [
            AppNotification(
                type: .like,
                title: "New Like",
                body: "Someone liked your post about Swift programming",
                data: ["post_id": "123", "user_id": "456"],
                priority: .normal
            ),
            AppNotification(
                type: .message,
                title: "New Message",
                body: "You have a new message from Alex",
                data: ["sender_id": "789", "conversation_id": "101"],
                priority: .high
            ),
            AppNotification(
                type: .achievement,
                title: "Achievement Unlocked!",
                body: "You've completed your first course! 🎉",
                data: ["achievement_id": "first_course", "course_id": "swift_basics"],
                priority: .high
            ),
            AppNotification(
                type: .follow,
                title: "New Follower",
                body: "Sarah started following you",
                data: ["follower_id": "999"],
                priority: .normal
            )
        ]
        
        for notification in mockNotifications {
            addNotification(notification)
        }
    }
    
    // MARK: - Utility
    
    func getNotifications(for type: NotificationType) -> [AppNotification] {
        return notifications.filter { $0.type == type }
    }
    
    func getUnreadNotifications() -> [AppNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    func getNotificationCount(for type: NotificationType) -> Int {
        return notifications.filter { $0.type == type }.count
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification Views

struct NotificationBadge: View {
    let count: Int
    
    var body: some View {
        if count > 0 {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                
                Text("\(min(count, 99))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}

struct NotificationListView: View {
    @ObservedObject var notificationManager = RealTimeNotificationManager.shared
    
    var body: some View {
        NavigationView {
            List {
                if notificationManager.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Notifications")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("You'll see notifications here when you receive them")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(notificationManager.notifications) { notification in
                        NotificationRow(notification: notification)
                    }
                    .onDelete(perform: deleteNotifications)
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Mark All as Read") {
                            notificationManager.markAllAsRead()
                        }
                        
                        Button("Clear All", role: .destructive) {
                            notificationManager.clearNotifications()
                        }
                        
                        Button("Add Test Notifications") {
                            notificationManager.addMockNotifications()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func deleteNotifications(offsets: IndexSet) {
        for index in offsets {
            let notification = notificationManager.notifications[index]
            notificationManager.deleteNotification(notification.id)
        }
    }
}

struct NotificationRow: View {
    let notification: RealTimeNotificationManager.AppNotification
    @ObservedObject var notificationManager = RealTimeNotificationManager.shared
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: notification.type.icon)
                .font(.title2)
                .foregroundColor(notification.type.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                
                Text(notification.body)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(RelativeDateTimeFormatter().localizedString(for: notification.timestamp, relativeTo: Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            notificationManager.markAsRead(notification.id)
        }
    }
}

#Preview {
    NotificationListView()
}