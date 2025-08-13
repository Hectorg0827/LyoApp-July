import Foundation

// MARK: - LyoBackendJune Integration Configuration
struct BackendConfig {
    
    // MARK: - Environment Management
    enum Environment: CaseIterable {
        case development
        case staging  
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "http://localhost:8000"  // LyoBackendJune local development
            case .staging:
                return "https://staging-lyo-api.herokuapp.com"
            case .production:
                return "https://lyo-api.herokuapp.com"
            }
        }
        
        var wsURL: String {
            return baseURL.replacingOccurrences(of: "http", with: "ws")
        }
    }
    
    // Current environment (change for different builds)
    static let current: Environment = .development
    
    // API Configuration
    static let apiVersion = "/api/v1"
    static let fullBaseURL = current.baseURL + apiVersion
    
    // Request Configuration
    static let timeoutInterval: TimeInterval = 30.0
    static let maxRetryAttempts = 3
    
    // MARK: - API Endpoints (matching LyoBackendJune structure)
    enum Endpoints {
        // Health & Status
        static let health = "/health"
        static let status = "/status"
        
        // Authentication & User Management
        static let register = "/auth/register"
        static let login = "/auth/login"
        static let logout = "/auth/logout"
        static let refreshToken = "/auth/refresh"
        static let resetPassword = "/auth/reset-password"
        
        // User Profile & Settings
        static let userProfile = "/users/profile"
        static let updateProfile = "/users/profile"
        static let userSettings = "/users/settings"
        static let userStats = "/users/stats"
        
        // Social Feed & Posts
        static let feed = "/feed"
        static let posts = "/posts"
        static let createPost = "/posts"
        static let likePost = "/posts/{id}/like"
        static let sharePost = "/posts/{id}/share"
        static let commentPost = "/posts/{id}/comments"
        
        // Educational Content
        static let courses = "/courses"
        static let courseDetails = "/courses/{id}"
        static let courseProgress = "/courses/{id}/progress"
        static let videos = "/videos"
        static let ebooks = "/ebooks"
        static let searchContent = "/search/content"
        
        // Learning & Progress Tracking
        static let learningProgress = "/learning/progress"
        static let learningHistory = "/learning/history"
        static let bookmarks = "/learning/bookmarks"
        static let achievements = "/learning/achievements"
        
        // AI Integration (matching backend's Gemini integration)
        static let aiChat = "/ai/chat"
        static let aiStudyMode = "/ai/study-mode"
        static let aiRecommendations = "/ai/recommendations"
        static let aiAnalytics = "/ai/analytics"
        
        // Community Features
        static let communities = "/communities"
        static let joinCommunity = "/communities/{id}/join"
        static let communityPosts = "/communities/{id}/posts"
        static let discussions = "/discussions"
        
        // Gamification System
        static let gamificationStats = "/gamification/stats"
        static let leaderboard = "/gamification/leaderboard"
        static let badges = "/gamification/badges"
        static let rewards = "/gamification/rewards"
        
        // Stories & Media
        static let stories = "/stories"
        static let uploadStory = "/stories/upload"
        static let viewStory = "/stories/{id}/view"
        
        // Search & Discovery
        static let search = "/search"
        static let trending = "/trending"
        static let recommendations = "/recommendations"
        
        // Analytics & Tracking
        static let analytics = "/analytics"
        static let eventTracking = "/analytics/events"
        static let userBehavior = "/analytics/behavior"
    }
    
    // MARK: - WebSocket Events (if backend supports real-time features)
    enum WebSocketEvents {
        static let newMessage = "new_message"
        static let userOnline = "user_online"
        static let userOffline = "user_offline"
        static let newNotification = "new_notification"
        static let liveUpdates = "live_updates"
    }
    
    // MARK: - Error Codes (matching backend error responses)
    enum ErrorCodes {
        static let unauthorized = 401
        static let forbidden = 403
        static let notFound = 404
        static let serverError = 500
        static let networkError = -1
        static let timeoutError = -2
    }
    
    // MARK: - Feature Flags (based on backend capabilities)
    struct FeatureFlags {
        static let aiChatEnabled = true
        static let gamificationEnabled = true
        static let communitiesEnabled = true
        static let storiesEnabled = true
        static let realTimeUpdatesEnabled = true
        static let analyticsEnabled = true
        static let offlineModeEnabled = true
    }
}
