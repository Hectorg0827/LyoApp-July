import UserNotifications
import UIKit
import Foundation

/// Production-ready push notification manager
@MainActor 
class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    // MARK: - Published Properties
    @Published var hasPermission = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var notificationSettings: UNNotificationSettings?
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private let center = UNUserNotificationCenter.current()
    private let analytics = Analytics.shared
    
    override init() {
        super.init()
        center.delegate = self
        checkCurrentPermissions()
        
        print("🔔 PushNotificationManager initialized")
    }
    
    // MARK: - Permission Management
    
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
            
            await MainActor.run {
                hasPermission = granted
                analytics.track("push_permission_requested", properties: ["granted": granted])
            }
            
            if granted {
                await registerForRemoteNotifications()
                print("✅ Push notifications permission granted")
            } else {
                print("❌ Push notifications permission denied")
            }
            
        } catch {
            print("❌ Failed to request push permission: \(error)")
            analytics.trackAPIError(endpoint: "push_permission", statusCode: -1, errorType: error.localizedDescription)
        }
        
        await updateAuthorizationStatus()
    }
    
    private func checkCurrentPermissions() {
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    private func updateAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        
        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
            notificationSettings = settings
            hasPermission = settings.authorizationStatus == .authorized || 
                           settings.authorizationStatus == .provisional
        }
    }
    
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Device Token Management
    
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        print("📱 Device token received: \(tokenString.prefix(10))...")
        
        Task {
            await registerDeviceToken(tokenString)
        }
        
        analytics.track("device_token_registered", properties: [
            "token_length": tokenString.count
        ])
    }
    
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
        
        analytics.trackAPIError(
            endpoint: "device_token_registration",
            statusCode: -1,
            errorType: error.localizedDescription
        )
    }
    
    private func registerDeviceToken(_ token: String) async {
        struct DeviceTokenRequest: Codable {
            let deviceToken: String
            let platform: String = "ios"
            let appVersion: String
            let osVersion: String
            let deviceModel: String
            
            init(deviceToken: String) {
                self.deviceToken = deviceToken
                self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                self.osVersion = ProcessInfo.processInfo.operatingSystemVersionString
                self.deviceModel = UIDevice.current.model
            }
        }
        
        struct DeviceTokenResponse: Codable {
            let success: Bool
            let deviceId: String?
        }
        
        do {
            let response: DeviceTokenResponse = try await networkManager.apiClient.post(
                "push/device-token",
                body: DeviceTokenRequest(deviceToken: token)
            )
            
            if response.success {
                UserDefaults.standard.set(token, forKey: "device_token")
                print("✅ Device token registered with backend")
                
                analytics.track("device_token_backend_registered", properties: [
                    "device_id": response.deviceId ?? "unknown"
                ])
            }
            
        } catch {
            print("❌ Failed to register device token with backend: \(error)")
            
            analytics.trackAPIError(
                endpoint: "push/device-token",
                statusCode: -1,
                errorType: error.localizedDescription
            )
        }
    }
    
    // MARK: - Local Notifications
    
    func scheduleLocalNotification(
        title: String,
        body: String,
        identifier: String,
        timeInterval: TimeInterval,
        userInfo: [String: Any] = [:]
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            print("📅 Local notification scheduled: \(identifier)")
            
            analytics.track("local_notification_scheduled", properties: [
                "identifier": identifier,
                "time_interval": timeInterval
            ])
            
        } catch {
            print("❌ Failed to schedule local notification: \(error)")
        }
    }
    
    func cancelLocalNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled local notification: \(identifier)")
        
        analytics.track("local_notification_cancelled", properties: [
            "identifier": identifier
        ])
    }
    
    func cancelAllLocalNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all local notifications")
        
        analytics.track("all_local_notifications_cancelled")
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = count
            
            if count == 0 {
                print("🔢 Badge cleared")
            } else {
                print("🔢 Badge count updated: \(count)")
            }
            
            analytics.track("badge_count_updated", properties: [
                "count": count
            ])
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLink(from userInfo: [AnyHashable: Any]) {
        guard let deepLink = userInfo["deep_link"] as? String else { return }
        
        print("🔗 Handling deep link: \(deepLink)")
        
        // Parse deep link and route to appropriate screen
        if deepLink.contains("course/") {
            handleCourseDeepLink(deepLink, userInfo: userInfo)
        } else if deepLink.contains("post/") {
            handlePostDeepLink(deepLink, userInfo: userInfo)
        } else if deepLink.contains("profile/") {
            handleProfileDeepLink(deepLink, userInfo: userInfo)
        } else {
            // Generic deep link handling
            NotificationCenter.default.post(
                name: .deepLinkReceived,
                object: DeepLink(url: deepLink, source: "push_notification", userInfo: userInfo)
            )
        }
        
        analytics.track("deep_link_handled", properties: [
            "deep_link": deepLink,
            "source": "push_notification"
        ])
    }
    
    private func handleCourseDeepLink(_ deepLink: String, userInfo: [AnyHashable: Any]) {
        if let courseId = extractCourseId(from: deepLink) {
            NotificationCenter.default.post(
                name: .openCourse,
                object: courseId
            )
            
            analytics.track("course_opened_from_push", properties: [
                "course_id": courseId
            ])
        }
    }
    
    private func handlePostDeepLink(_ deepLink: String, userInfo: [AnyHashable: Any]) {
        if let postId = extractPostId(from: deepLink) {
            NotificationCenter.default.post(
                name: .openPost,
                object: postId
            )
            
            analytics.track("post_opened_from_push", properties: [
                "post_id": postId
            ])
        }
    }
    
    private func handleProfileDeepLink(_ deepLink: String, userInfo: [AnyHashable: Any]) {
        if let userId = extractUserId(from: deepLink) {
            NotificationCenter.default.post(
                name: .openProfile,
                object: userId
            )
            
            analytics.track("profile_opened_from_push", properties: [
                "user_id": userId
            ])
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractCourseId(from deepLink: String) -> String? {
        let pattern = #"course/([a-zA-Z0-9\-]+)"#
        return extractId(from: deepLink, pattern: pattern)
    }
    
    private func extractPostId(from deepLink: String) -> String? {
        let pattern = #"post/([a-zA-Z0-9\-]+)"#
        return extractId(from: deepLink, pattern: pattern)
    }
    
    private func extractUserId(from deepLink: String) -> String? {
        let pattern = #"profile/([a-zA-Z0-9\-]+)"#
        return extractId(from: deepLink, pattern: pattern)
    }
    
    private func extractId(from deepLink: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: deepLink, range: NSRange(deepLink.startIndex..., in: deepLink)) else {
            return nil
        }
        
        let range = Range(match.range(at: 1), in: deepLink)!
        return String(deepLink[range])
    }
    
    // MARK: - Settings
    
    func openNotificationSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        
        Task { @MainActor in
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
                
                analytics.track("notification_settings_opened")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        
        let userInfo = notification.request.content.userInfo
        
        print("🔔 Will present notification: \(notification.request.identifier)")
        
        analytics.track("notification_received_foreground", properties: [
            "identifier": notification.request.identifier,
            "category": notification.request.content.categoryIdentifier
        ])
        
        // Show notification even when app is in foreground
        return [.banner, .badge, .sound]
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        
        let userInfo = response.notification.request.content.userInfo
        
        print("🔔 Did receive notification response: \(response.actionIdentifier)")
        
        analytics.track("notification_tapped", properties: [
            "identifier": response.notification.request.identifier,
            "action": response.actionIdentifier
        ])
        
        // Handle notification tap
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // User tapped the notification
            handleDeepLink(from: userInfo)
        }
        
        // Clear the badge when user interacts with notification
        await MainActor.run {
            updateBadgeCount(0)
        }
    }
}

// MARK: - Deep Link Support
struct DeepLink {
    let url: String
    let source: String
    let userInfo: [AnyHashable: Any]
}

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
    static let openCourse = Notification.Name("openCourse")
    static let openPost = Notification.Name("openPost")
    static let openProfile = Notification.Name("openProfile")
}

// MARK: - Notification Categories
extension PushNotificationManager {
    
    func registerNotificationCategories() {
        let courseCompleteAction = UNNotificationAction(
            identifier: "VIEW_COURSE",
            title: "View Course",
            options: [.foreground]
        )
        
        let courseCategory = UNNotificationCategory(
            identifier: "COURSE_COMPLETE",
            actions: [courseCompleteAction],
            intentIdentifiers: [],
            options: []
        )
        
        let likeAction = UNNotificationAction(
            identifier: "LIKE_POST",
            title: "❤️ Like",
            options: []
        )
        
        let replyAction = UNNotificationAction(
            identifier: "REPLY_POST",
            title: "💬 Reply",
            options: [.foreground]
        )
        
        let postCategory = UNNotificationCategory(
            identifier: "POST_INTERACTION",
            actions: [likeAction, replyAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([courseCategory, postCategory])
    }
}
