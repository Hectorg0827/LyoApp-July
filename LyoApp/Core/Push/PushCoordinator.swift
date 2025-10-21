import Foundation
import UserNotifications
import UIKit

/// Push notification coordinator for device registration and deep linking
@MainActor
class PushCoordinator: NSObject, ObservableObject {
    
    static let shared = PushCoordinator()
    
    @Published var isRegistered = false
    @Published var deviceToken: String?
    @Published var pendingDeepLink: String?
    
    private let apiClient: APIClient
    private let authManager: AuthManager
    
    init(apiClient: APIClient? = nil, authManager: AuthManager? = nil) {
        // Use dependency injection or create defaults
        self.authManager = authManager ?? AuthManager()
        self.apiClient = apiClient ?? APIClient()
        
        super.init()
        
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permission and Registration
    
    /// Request notification permission and register for remote notifications
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            
            if granted {
                print("✅ Notification permission granted")
                await registerForRemoteNotifications()
                return true
            } else {
                print("❌ Notification permission denied")
                return false
            }
            
        } catch {
            print("❌ Notification permission error: \(error)")
            return false
        }
    }
    
    /// Register for remote notifications
    private func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Device Token Management
    
    /// Handle successful device token registration
    func didReceiveDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token
        
        print("📱 Device token received: \(token.prefix(16))...")
        
        // Register with backend if user has auth token
        Task {
            if await authManager.isAuthenticated {
                await registerDeviceWithBackend(token)
            } else {
                print("📝 Device token saved, will register when user authenticates")
            }
        }
    }
    
    /// Handle device token registration failure
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
        isRegistered = false
    }
    
    /// Register device token with backend
    private func registerDeviceWithBackend(_ token: String) async {
        do {
            let request = DeviceRegistrationRequest(
                deviceToken: token,
                platform: "ios",
                locale: Locale.current.identifier,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            )
            
            let _: DeviceRegistrationResponse = try await apiClient.post("push/devices", body: request)
            
            isRegistered = true
            print("✅ Device registered with backend")
            
        } catch {
            print("❌ Failed to register device with backend: \(error)")
            isRegistered = false
        }
    }
    
    // MARK: - Deep Link Handling
    
    /// Handle incoming push notification with deep link
    func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        print("📧 Received push notification: \(userInfo)")
        
        // Extract course ID from push payload
        if let courseId = userInfo["course_id"] as? String {
            let deepLink = "lyo://course/\(courseId)"
            handleDeepLink(deepLink)
        }
    }
    
    /// Handle deep link URL
    func handleDeepLink(_ urlString: String) {
        print("🔗 Handling deep link: \(urlString)")
        
        // If user is not authenticated, store the deep link for later
        Task {
            if !(await authManager.isAuthenticated) {
                print("💾 Storing deep link for post-authentication")
                pendingDeepLink = urlString
                return
            }
            
            // Route the deep link immediately
            routeDeepLink(urlString)
        }
    }
    
    /// Execute pending deep link after authentication
    func executePendingDeepLink() {
        guard let pendingLink = pendingDeepLink else { return }
        
        print("🚀 Executing pending deep link: \(pendingLink)")
        pendingDeepLink = nil
        routeDeepLink(pendingLink)
    }
    
    /// Route deep link to appropriate screen
    private func routeDeepLink(_ urlString: String) {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Invalid deep link URL: \(urlString)")
            return
        }
        
        // Parse the deep link
        switch components.host {
        case "course":
            if let courseId = components.path.components(separatedBy: "/").last {
                routeToCourse(courseId: courseId)
            }
            
        default:
            print("❌ Unknown deep link host: \(components.host ?? "nil")")
        }
    }
    
    /// Navigate to course screen
    private func routeToCourse(courseId: String) {
        print("📚 Routing to course: \(courseId)")
        
        // Post notification for the app to handle navigation
        NotificationCenter.default.post(
            name: .deepLinkToCourse,
            object: nil,
            userInfo: ["courseId": courseId]
        )
    }
    
    // MARK: - Public Methods
    
    /// Check if notifications are enabled
    func checkNotificationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Re-register device token after authentication
    func reregisterIfNeeded() async {
        if let token = deviceToken, !isRegistered, await authManager.isAuthenticated {
            await registerDeviceWithBackend(token)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushCoordinator: UNUserNotificationCenterDelegate {
    
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 Notification received in foreground")
        
        // Extract deep link info
        let userInfo = notification.request.content.userInfo
        Task { @MainActor in
            handlePushNotification(userInfo)
        }
        
        // Show notification even when app is active
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 Notification tapped")
        
        // Extract deep link info
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            handlePushNotification(userInfo)
        }
        
        completionHandler()
    }
}

// MARK: - Request/Response Models
private struct DeviceRegistrationRequest: Codable {
    let deviceToken: String
    let platform: String
    let locale: String
    let appVersion: String
}

private struct DeviceRegistrationResponse: Codable {
    let success: Bool
}

// MARK: - Notification Names
extension Notification.Name {
    static let deepLinkToCourse = Notification.Name("deepLinkToCourse")
}