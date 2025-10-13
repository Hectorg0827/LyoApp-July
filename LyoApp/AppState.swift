
import SwiftUI
import Combine

// MARK: - Notification Names
extension NSNotification.Name {
    static let userDidLogin = NSNotification.Name("userDidLogin")
    static let userDidLogout = NSNotification.Name("userDidLogout")
}

// MARK: - Loading States
enum LoadingState: Equatable {
    case idle
    case loading(message: String? = nil)
    case success
    case failure(AppError)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var error: AppError? {
        if case .failure(let error) = self { return error }
        return nil
    }
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.success, .success):
            return true
        case (.loading(let lhsMessage), .loading(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Avatar State
enum AvatarState {
    case idle, listening, thinking, speaking
}

// MARK: - Error Types
enum AppError: LocalizedError, Equatable {
    case networkError
    case serverError(message: String)
    case invalidResponse
    case authenticationFailed
    case dataCorruption
    case microphonePermissionDenied
    case cameraPermissionDenied
    case photoLibraryPermissionDenied
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .serverError(let message):
            return "Server error: \(message). Please try again later."
        case .invalidResponse:
            return "Something went wrong. Please try again."
        case .authenticationFailed:
            return "Authentication failed. Please log in again."
        case .dataCorruption:
            return "Data corruption detected. The app will restore from backup."
        case .microphonePermissionDenied:
            return "Microphone access is required for voice interactions. Please enable it in Settings."
        case .cameraPermissionDenied:
            return "Camera access is required for visual learning features. Please enable it in Settings."
        case .photoLibraryPermissionDenied:
            return "Photo library access is required to save your progress. Please enable it in Settings."
        case .unknownError(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var recoveryAction: String {
        switch self {
        case .networkError:
            return "Retry"
        case .serverError:
            return "Try Again"
        case .invalidResponse:
            return "Retry"
        case .authenticationFailed:
            return "Log In"
        case .dataCorruption:
            return "Restore"
        case .microphonePermissionDenied, .cameraPermissionDenied, .photoLibraryPermissionDenied:
            return "Open Settings"
        case .unknownError:
            return "Retry"
        }
    }
}

// LoadingState is defined in ErrorHandling.swift

/// Global application state manager
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isDarkMode = false
    @Published var selectedTab: MainTab = .home
    @Published var isShowingPost = false
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var showXPGain = false
    @Published var showLevelUp = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var alertActions: [AlertAction] = []
    @Published var errorMessage: String?
    @Published var learningResources: [LearningResource] = []
    
    // MARK: - User Data Manager Integration
    // TODO: Re-enable after fixing circular dependency
    // private let userDataManager = UserDataManager.shared
    
    // MARK: - Lyo AI State
    @Published var isLyoAwake = false
    @Published var isListeningForWakeWord = true
    @Published var isLyoSpeaking = false
    @Published var hasActiveSession = false
    @Published var lastSessionDate: Date?
    @Published var currentLearningObjective: String?
    
    // MARK: - Avatar Companion State
    @Published var isAvatarPresented: Bool = false
    @Published var avatarState: AvatarState = .idle
    @Published var liveTranscript: String = ""
    @Published var currentAvatarContext: Any? = nil
    @Published var showFloatingCompanion: Bool = false
    
    // MARK: - Learning Path State
    @Published var currentLearningPath: LearningPath?
    @Published var showingPathSelection = false
    @Published var topicDefinitionComplete = false
    @Published var currentTopic: String?
    @Published var pathProgress: Double = 0.0
    @Published var currentStepIndex = 0
    
    // MARK: - Error Handling & Loading States
    @Published var currentError: AppError? = nil
    @Published var loadingState: LoadingState = .idle
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load saved preferences
        loadUserDefaults()
        
        // Load authentication state
        loadAuthenticationState()
        
        // Set up user session monitoring
        setupSessionMonitoring()
        
        // Sync with UserDataManager
        setupUserDataManagerSync()
    }
    
    private func setupUserDataManagerSync() {
        // TODO: Re-enable UserDataManager sync
        // Sync current user from UserDataManager
        // currentUser = userDataManager.currentUser
        // isAuthenticated = currentUser != nil
        
        // Listen for user data changes
        // userDataManager.$currentUser
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] user in
        //         self?.currentUser = user
        //         self?.isAuthenticated = user != nil
        //     }
        //     .store(in: &cancellables)
    }
    
    // MARK: - User Management
    
    /// Set authenticated user and sync with data manager
    func setAuthenticatedUser(_ user: User) {
        // TODO: Re-enable UserDataManager sync
        // userDataManager.setCurrentUser(user)
        currentUser = user
        isAuthenticated = true
        setupAPIAuthentication(for: user)
        saveUserPreferences()
    }
    
    /// Set authentication tokens after successful login
    func setAuthTokens(accessToken: String, refreshToken: String, userId: String? = nil) {
        // Persist securely
        TokenStore.shared.save(accessToken: accessToken, refreshToken: refreshToken, userId: userId)
        
        // Keep API client in sync with real tokens
        APIClient.shared.setAuthToken(accessToken, refreshToken: refreshToken, userId: userId)
        
        // Clear any legacy mode flags (cleanup)
        UserDefaults.standard.removeObject(forKey: "isWorkingMode")
        UserDefaults.standard.removeObject(forKey: "isDemoMode")
        
        isAuthenticated = true
        
        // If we have user data, ensure API auth is configured (no-op if tokens already set)
        if let user = currentUser {
            setupAPIAuthentication(for: user)
        }
        
        // Connect WebSocket using the real backend user id (String)
        if let backendUserId = userId, !backendUserId.isEmpty {
            LyoWebSocketService.shared.connect(userId: backendUserId, appState: self)
        } else if let stored = TokenStore.shared.loadTokens()?.userId, !stored.isEmpty {
            LyoWebSocketService.shared.connect(userId: stored, appState: self)
        }
    }
    
    /// Load saved authentication state
    func loadAuthenticationState() {
        if let tokens = TokenStore.shared.loadTokens() {
            // Sync tokens into API client on launch
            APIClient.shared.setAuthToken(tokens.accessToken, refreshToken: tokens.refreshToken, userId: tokens.userId)
            
            isAuthenticated = true
            // Try to get current user info from backend
            Task {
                try await getCurrentUserFromBackend()
            }
        } else {
            isAuthenticated = false
        }
    }
    
    /// Get current user from backend using stored token
    private func getCurrentUserFromBackend() async throws {
        do {
            let userProfile = try await APIClient.shared.getCurrentUser()
            let domainUser = convertUserProfileToDomainUser(userProfile)
            await MainActor.run {
                currentUser = domainUser
                isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                // Token might be expired, clear authentication
                TokenStore.shared.clearAllTokens()
                isAuthenticated = false
                currentUser = nil
            }
        }
    }
    
    /// Log out current user
    func logoutUser() {
        // TODO: Re-enable UserDataManager sync
        // userDataManager.clearUserData()
        currentUser = nil
        isAuthenticated = false
        TokenStore.shared.clearAllTokens()
        clearAPIAuthentication()
        
        // Clear session state
        hasActiveSession = false
        currentLearningPath = nil
        currentTopic = nil
        pathProgress = 0.0
        currentStepIndex = 0
        
        // Clear legacy mode flags (cleanup)
        UserDefaults.standard.removeObject(forKey: "isWorkingMode")
        UserDefaults.standard.removeObject(forKey: "isDemoMode")
        
        saveUserPreferences()
        
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    /// Sign out current user (async version of logoutUser)
    @MainActor
    func signOut() async {
        logoutUser()
    }
    
    // initializeServices is defined in AppStateExtensions.swift
    
    private func setupAPIAuthentication(for: User) {
        // Use real tokens if available; do NOT overwrite with mock tokens
        if let tokens = TokenStore.shared.loadTokens() {
            APIClient.shared.setAuthToken(tokens.accessToken, refreshToken: tokens.refreshToken, userId: tokens.userId)
        } else {
            // If no tokens are available, leave API client as-is (likely unauthenticated)
            print("⚠️ setupAPIAuthentication called with no stored tokens")
        }
    }
    
    // saveUserPreferences is defined in AppStateExtensions.swift
    
    private func loadUserDefaults() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        isListeningForWakeWord = UserDefaults.standard.object(forKey: "isListeningForWakeWord") as? Bool ?? true
        hasActiveSession = UserDefaults.standard.bool(forKey: "hasActiveLyoSession")
        currentLearningObjective = UserDefaults.standard.string(forKey: "currentLearningObjective")
        
        // Load avatar companion state
        showFloatingCompanion = UserDefaults.standard.bool(forKey: "showFloatingCompanion")
        
        // Load learning path state
        currentTopic = UserDefaults.standard.string(forKey: "currentTopic")
        if let pathString = UserDefaults.standard.string(forKey: "currentLearningPath"),
           let path = LearningPath(rawValue: pathString) {
            currentLearningPath = path
        }
        pathProgress = UserDefaults.standard.double(forKey: "pathProgress")
        topicDefinitionComplete = currentTopic != nil
        
        if let lastSession = UserDefaults.standard.object(forKey: "lastLyoSession") as? Date {
            lastSessionDate = lastSession
            // If last session was within 24 hours, consider it resumable
            let dayAgo = Date().addingTimeInterval(-24 * 60 * 60)
            if lastSession > dayAgo {
                hasActiveSession = true
            }
        }
    }
    
    private func setupSessionMonitoring() {
        // Monitor authentication state changes
        NotificationCenter.default.publisher(for: .userDidLogin)
            .sink { [weak self] notification in
                if let user = notification.object as? User {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    self?.setupAPIAuthentication(for: user)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .userDidLogout)
            .sink { [weak self] _ in
                self?.currentUser = nil
                self?.isAuthenticated = false
                self?.clearAPIAuthentication()
            }
            .store(in: &cancellables)
    }
    
    private func clearAPIAuthentication() {
        // Clear API authentication using the client’s proper method
        APIClient.shared.clearAuthTokens()
        
        // Disconnect WebSocket
        LyoWebSocketService.shared.disconnect()
    }
    
    /// Convert UserProfile to domain User model
    private func convertUserProfileToDomainUser(_ userProfile: UserProfile) -> User {
        return User(
            id: UUID(uuidString: userProfile.id) ?? UUID(),
            username: userProfile.username,
            email: userProfile.email,
            fullName: userProfile.fullName,
            bio: userProfile.bio,
            profileImageURL: userProfile.profileImageUrl != nil ? URL(string: userProfile.profileImageUrl!) : nil,
            followers: userProfile.followersCount,
            following: userProfile.followingCount,
            posts: userProfile.postsCount,
            joinedAt: Date(), // Use current date as fallback
            experience: 0,
            level: 1
        )
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
    
    func showPost() {
        isShowingPost = true
    }
    
    func hidePost() {
        isShowingPost = false
    }
    
    func addNotification(_ notification: AppNotification) {
        notifications.append(notification)
    }
    
    func removeNotification(_ id: UUID) {
        notifications.removeAll { $0.id == id }
    }
    
    func showXPGain(amount: Int, reason: String) {
        // Implementation for showing XP gain animation
        showXPGain = true
        // Auto-hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showXPGain = false
        }
    }
    
    func showLevelUp(newLevel: Int) {
        // Implementation for showing level up notification
        showLevelUp = true
        // Auto-hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showLevelUp = false
        }
    }
    
    func showAlert(title: String, message: String, actions: [AlertAction]) {
        alertTitle = title
        alertMessage = message
        alertActions = actions
        showAlert = true
    }
    
    // MARK: - Lyo AI Management
    func awakeLyo() {
        isLyoAwake = true
        hasActiveSession = true
        // Automatically switch to AI Avatar tab when awakened
        selectedTab = .aiAvatar
        
        // Add haptic feedback for awakening (SwiftUI compatible)
        // Note: Haptic feedback can be implemented with SwiftUI sensory feedback when available
    }
    
    func sleepLyo() {
        isLyoAwake = false
        isLyoSpeaking = false
        // Don't end session immediately - allow for resumption
    }
    
    func startLyoSession() {
        hasActiveSession = true
        lastSessionDate = Date()
        // Save session start to UserDefaults for persistence
        UserDefaults.standard.set(Date(), forKey: "lastLyoSession")
    }
    
    func endLyoSession() {
        hasActiveSession = false
        currentLearningObjective = nil
        isLyoAwake = false
        isLyoSpeaking = false
        
        // Save session data
        UserDefaults.standard.set(false, forKey: "hasActiveLyoSession")
        UserDefaults.standard.removeObject(forKey: "currentLearningObjective")
    }
    
    func setLearningObjective(_ objective: String) {
        currentLearningObjective = objective
        UserDefaults.standard.set(objective, forKey: "currentLearningObjective")
    }
    
    func toggleWakeWordListening() {
        isListeningForWakeWord.toggle()
        UserDefaults.standard.set(isListeningForWakeWord, forKey: "isListeningForWakeWord")
    }
    
    // MARK: - Avatar Companion Management
    func presentAvatar(with context: Any? = nil) {
        currentAvatarContext = context
        isAvatarPresented = true
        avatarState = .idle
        
        // Enable floating companion after first interaction
        if !showFloatingCompanion {
            showFloatingCompanion = true
            UserDefaults.standard.set(true, forKey: "showFloatingCompanion")
        }
    }
    
    func dismissAvatar() {
        isAvatarPresented = false
        avatarState = .idle
        liveTranscript = ""
        currentAvatarContext = nil
    }
    
    func updateAvatarState(_ state: AvatarState) {
        avatarState = state
    }
    
    func updateLiveTranscript(_ transcript: String) {
        liveTranscript = transcript
    }
    
    func setAvatarContext(_ context: Any?) {
        currentAvatarContext = context
    }
    
    // MARK: - Learning Path Management
    func setCurrentTopic(_ topic: String) {
        currentTopic = topic
        topicDefinitionComplete = true
        showingPathSelection = true
        UserDefaults.standard.set(topic, forKey: "currentTopic")
    }
    
    func selectLearningPath(_ path: LearningPath) {
        currentLearningPath = path
        showingPathSelection = false
        pathProgress = 0.0
        currentStepIndex = 0
        
        // Save learning path selection
        UserDefaults.standard.set(path.rawValue, forKey: "currentLearningPath")
        UserDefaults.standard.set(0.0, forKey: "pathProgress")
    }
    
    func updatePathProgress(_ progress: Double) {
        pathProgress = progress
        UserDefaults.standard.set(progress, forKey: "pathProgress")
    }
    
    func completeCurrentPath() {
        currentLearningPath = nil
        pathProgress = 0.0
        currentStepIndex = 0
        showingPathSelection = false
        
        // Clear saved state
        UserDefaults.standard.removeObject(forKey: "currentLearningPath")
        UserDefaults.standard.removeObject(forKey: "pathProgress")
    }
    
    func resetLearningSession() {
        currentTopic = nil
        currentLearningPath = nil
        topicDefinitionComplete = false
        showingPathSelection = false
        pathProgress = 0.0
        currentStepIndex = 0
        
        // Clear all saved learning state
        UserDefaults.standard.removeObject(forKey: "currentTopic")
        UserDefaults.standard.removeObject(forKey: "currentLearningPath")
        UserDefaults.standard.removeObject(forKey: "pathProgress")
    }
    
    // MARK: - Error Handling
    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            if let appError = error as? AppError {
                self.currentError = appError
                self.loadingState = .failure(appError)
            } else {
                let unknownError = AppError.unknownError(error.localizedDescription)
                self.currentError = unknownError
                self.loadingState = .failure(unknownError)
            }
        }
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            if case .failure = self.loadingState {
                self.loadingState = .idle
            }
        }
    }
    
    func setLoading(_ message: String? = nil) {
        DispatchQueue.main.async {
            self.loadingState = .loading(message: message)
        }
    }
    
    func setSuccess() {
        DispatchQueue.main.async {
            self.loadingState = .success
        }
    }
}

// MARK: - Supporting Types
struct AlertAction {
    let title: String
    let style: AlertActionStyle
    let action: () -> Void
    
    enum AlertActionStyle {
        case `default`
        case cancel
        case destructive
    }
}

enum MainTab: String, CaseIterable {
    case home = "Home"
    case discover = "Discover"
    case aiAvatar = "AI Avatar"
    case post = "Post"
    case more = "More"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .discover: return "safari.fill"
        case .aiAvatar: return "brain.head.profile"
        case .post: return "plus"
        case .more: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Accessibility Extensions

extension MainTab {
    var accessibleName: String {
        switch self {
        case .home: return "Home Feed"
        case .discover: return "Discover"
        case .aiAvatar: return "AI Avatar - Your AI Learning Companion"
        case .post: return "Create Post"
        case .more: return "More Options"
        }
    }
    
    var accessibilityIdentifier: String {
        switch self {
        case .home: return "home_tab"
        case .discover: return "discover_tab"
        case .aiAvatar: return "ai_avatar_tab"
        case .post: return "post_tab"
        case .more: return "profile_tab"
        }
    }
    
    var accessibilityDescription: String {
        switch self {
        case .home: return "View your personalized home feed with posts and updates"
        case .discover: return "Explore new content and trending topics"
        case .aiAvatar: return "Chat with your AI learning companion in an immersive environment"
        case .post: return "Create and share new content"
        case .more: return "Access profile, settings, and additional options"
        }
    }
}

enum LearningPath: String, CaseIterable {
    case quickOverview = "Quick Overview"
    case stepByStep = "Step-by-Step Guide"
    case fullCourse = "Full Course"
    
    var icon: String {
        switch self {
        case .quickOverview: return "eye.fill"
        case .stepByStep: return "list.number"
        case .fullCourse: return "graduationcap.fill"
        }
    }
    
    var description: String {
        switch self {
        case .quickOverview: return "Get a concise explanation and key concepts in 5-10 minutes"
        case .stepByStep: return "Follow a structured learning path with guided exercises"
        case .fullCourse: return "Dive deep with a comprehensive course and interactive classroom"
        }
    }
    
    var estimatedTime: String {
        switch self {
        case .quickOverview: return "5-10 min"
        case .stepByStep: return "30-45 min"
        case .fullCourse: return "2-4 hours"
        }
    }
}

struct AppNotification: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
    
    init(title: String, message: String, type: NotificationType, timestamp: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.message = message
        self.type = type
        self.timestamp = timestamp
    }
    
    enum NotificationType {
        case info, success, warning, error
    }
}

// MARK: - Notification Names

