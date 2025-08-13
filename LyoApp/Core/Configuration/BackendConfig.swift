import Foundation

// MARK: - Backend Configuration for LyoBackendJune Integration
struct BackendConfig {
    // MARK: - Environment Configuration
    static let environment: Environment = .development
    
    enum Environment {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "http://localhost:8000"  // LyoBackendJune local
            case .staging:
                return "https://staging-lyo-backend.herokuapp.com"
            case .production:
                return "https://lyo-backend.herokuapp.com"
            }
        }
        
        var apiVersion: String {
            return "/api/v1"
        }
        
        var fullAPIURL: String {
            return baseURL + apiVersion
        }
    }
    
    // MARK: - API Endpoints (matching LyoBackendJune structure)
    struct Endpoints {
        // Authentication
        static let register = "/auth/register"
        static let login = "/auth/login"
        static let refreshToken = "/auth/refresh"
        static let logout = "/auth/logout"
        
        // User Management
        static let userProfile = "/users/profile"
        static let updateProfile = "/users/profile"
        static let userFeed = "/users/feed"
        
        // Educational Content
        static let courses = "/courses"
        static let videos = "/videos"
        static let ebooks = "/ebooks"
        static let learningProgress = "/learning/progress"
        
        // Social Features
        static let posts = "/posts"
        static let communities = "/communities"
        static let stories = "/stories"
        
        // AI Features (matching backend's Gemini integration)
        static let aiChat = "/ai/chat"
        static let aiStudyMode = "/ai/study"
        static let aiRecommendations = "/ai/recommendations"
        
        // Gamification
        static let achievements = "/gamification/achievements"
        static let leaderboard = "/gamification/leaderboard"
        static let badges = "/gamification/badges"
        
        // Health Check
        static let health = "/health"
    }
    
    // MARK: - Request Configuration
    static let timeoutInterval: TimeInterval = 30.0
    static let maxRetryAttempts = 3
    
    // MARK: - WebSocket Configuration (if backend supports)
    static let webSocketURL = environment.baseURL.replacingOccurrences(of: "http", with: "ws")
}
