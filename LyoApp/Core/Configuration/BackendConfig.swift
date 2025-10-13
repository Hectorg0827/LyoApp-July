import Foundation

// MARK: - ⚠️ DEPRECATED: Use APIEnvironment instead
// This file is kept for compatibility but should not be used for new code
// All new configurations should use APIEnvironment.swift as the single source of truth

// MARK: - Backend Configuration for Enhanced LyoBackend Integration
struct BackendConfig {
    // MARK: - Environment Configuration
    static let environment: Environment = .production  // ✅ Use production backend
    
    enum Environment {
        case development
        case staging
        case production

        var baseURL: String {
            switch self {
            case .development:
                return "http://localhost:8000"  // Local LyoBackendJune server
            case .staging:
                return "https://lyo-backend-830162750094.us-central1.run.app"
            case .production:
                return "https://lyo-backend-830162750094.us-central1.run.app"
            }
        }

        var webSocketURL: String {
            switch self {
            case .development:
                return "ws://localhost:8000/ws"
            case .staging:
                return "wss://lyo-backend-830162750094.us-central1.run.app/ws"
            case .production:
                return "wss://lyo-backend-830162750094.us-central1.run.app/ws"
            }
        }

        var displayName: String {
            switch self {
            case .development:
                return "🛠️ Local LyoBackend (June)"
            case .staging:
                return "☁️ Staging Cloud Backend"
            case .production:
                return "☁️ Production Cloud Backend"
            }
        }

        var apiVersion: String {
            // Enhanced backend uses direct endpoints, not versioned paths
            return ""
        }

        var fullAPIURL: String {
            return baseURL + apiVersion
        }

        var isEnhanced: Bool {
            return self == .development  // Local backend has enhanced features
        }

        var allowsInsecureTransport: Bool {
            switch self {
            case .development:
                return true
            case .staging, .production:
                return false
            }
        }
    }
    
    // MARK: - API Endpoints (Enhanced Local Backend)
    struct Endpoints {
        // Authentication (may not be available in local backend)
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
        
        // 🚀 ENHANCED AI FEATURES (Superior AI v2.5.0)
        static let aiGenerate = "/ai/generate"  // Basic AI endpoint
        static let aiSuperiorGenerate = "/ai/superior/generate"  // ✅ Enhanced content generation
        static let aiSuperiorCourse = "/ai/superior/course"  // ✅ Adaptive course creation
        static let aiSuperiorAssessment = "/ai/superior/assessment"  // ✅ Socratic assessment
        static let aiStatus = "/ai/status"
        
        // Legacy AI endpoints (for compatibility)
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
    static let webSocketURL = environment.webSocketURL

    static var isLocalEnvironment: Bool {
        environment == .development
    }
}
