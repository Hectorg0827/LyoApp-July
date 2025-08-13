import Foundation

/// Configuration settings for Lyo AI Learn Buddy
struct LyoConfiguration {
    
    // MARK: - Backend Configuration
    static let backendURL = "http://localhost:8000"
    static let webSocketURL = "ws://localhost:8000"
    
    // MARK: - API Configuration
    static let apiTimeout: TimeInterval = 30.0
    static let maxRetries = 3
    static let retryDelay: TimeInterval = 2.0
    
    // MARK: - WebSocket Configuration
    static let webSocketTimeout: TimeInterval = 10.0
    static let webSocketPingInterval: TimeInterval = 30.0
    static let webSocketReconnectDelay: TimeInterval = 5.0
    static let maxWebSocketReconnectAttempts = 5
    
    // MARK: - Voice Recognition Configuration
    static let voiceRecognitionTimeout: TimeInterval = 30.0
    static let hotwordDebounceInterval: TimeInterval = 2.0
    static let supportedHotwords = ["hey lyo", "hi lio"]
    
    // MARK: - AI Configuration
    static let defaultDifficultyLevel = "beginner"
    static let defaultLanguage = "en"
    static let defaultLearningStyle = "adaptive"
    static let maxLearningObjectives = 5
    
    // MARK: - OpenAI API Configuration
    // Add your OpenAI API key here after obtaining it from https://platform.openai.com/api-keys
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"
    static let openAIBaseURL = "https://api.openai.com/v1"
    static let openAIModel = "gpt-4"
    static let maxTokensPerRequest = 2000
    static let maxCourseHours = 12
    
    // MARK: - UI Configuration
    static let animationDuration: TimeInterval = 0.3
    static let longAnimationDuration: TimeInterval = 0.5
    static let debounceDelay: TimeInterval = 0.5
    static let maxChatMessages = 100
    static let maxErrorHistory = 50
    
    // MARK: - Debug Configuration
    static let enableDebugLogging = true
    static let enableMockData = false
    static let enableOfflineMode = false
    
    // MARK: - Feature Flags
    static let enableVoiceActivation = true
    static let enableWebSocketChat = true
    static let enablePersonalization = true
    static let enableAdvancedAnalytics = true
    static let enableErrorReporting = true
    
    // MARK: - Environment Detection
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isProductionMode: Bool {
        return !isDebugMode
    }
    
    // MARK: - Dynamic Configuration
    static func getBackendURL() -> String {
        if isDebugMode {
            return backendURL
        } else {
            // In production, you might want to load this from a configuration file
            // or environment variable
            return "https://your-production-backend.com"
        }
    }
    
    static func getWebSocketURL() -> String {
        if isDebugMode {
            return webSocketURL
        } else {
            return "wss://your-production-backend.com"
        }
    }
    
    // MARK: - Logging Configuration
    static func log(_ message: String, level: LogLevel = .info) {
        guard enableDebugLogging || level == .error else { return }
        
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let prefix = level.prefix
        
        print("[\(timestamp)] \(prefix) \(message)")
    }
    
    enum LogLevel {
        case debug
        case info
        case warning
        case error
        
        var prefix: String {
            switch self {
            case .debug: return "🐛"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Configuration Manager

@MainActor
class LyoConfigurationManager: ObservableObject {
    static let shared = LyoConfigurationManager()
    
    @Published var currentConfiguration: LyoConfiguration = LyoConfiguration()
    @Published var isConfigurationLoaded = false
    
    private init() {
        loadConfiguration()
    }
    
    func loadConfiguration() {
        // Load configuration from UserDefaults or remote config
        // For now, we'll use the static configuration
        
        // You could implement remote configuration loading here
        // For example, loading from Firebase Remote Config or similar
        
        isConfigurationLoaded = true
        LyoConfiguration.log("Configuration loaded successfully")
    }
    
    func updateConfiguration(_ newConfig: LyoConfiguration) {
        currentConfiguration = newConfig
        saveConfiguration()
    }
    
    private func saveConfiguration() {
        // Save configuration to UserDefaults
        // Implementation depends on your specific needs
        LyoConfiguration.log("Configuration saved")
    }
}

// MARK: - Environment Variables

extension LyoConfiguration {
    /// Get environment variable or return default value
    static func getEnvironmentVariable(_ name: String, defaultValue: String = "") -> String {
        return ProcessInfo.processInfo.environment[name] ?? defaultValue
    }
    
    /// Check if running in specific environment
    static func isRunningInEnvironment(_ environment: String) -> Bool {
        return getEnvironmentVariable("ENVIRONMENT") == environment
    }
}

// MARK: - API Endpoints

extension LyoConfiguration {
    enum APIEndpoint {
        case health
        case courseOutline
        case lessonContent
        case mentorConversation
        case conversationHistory
        case rateInteraction
        case webSocket(userId: Int)
        
        var path: String {
            switch self {
            case .health:
                return "/ai/health"
            case .courseOutline:
                return "/ai/curriculum/course-outline"
            case .lessonContent:
                return "/ai/curriculum/lesson-content"
            case .mentorConversation:
                return "/ai/mentor/conversation"
            case .conversationHistory:
                return "/ai/mentor/history"
            case .rateInteraction:
                return "/ai/mentor/rate"
            case .webSocket(let userId):
                return "/ai/ws/\(userId)"
            }
        }
        
        var fullURL: String {
            return LyoConfiguration.getBackendURL() + path
        }
        
        var webSocketURL: String {
            return LyoConfiguration.getWebSocketURL() + path
        }
    }
}

// MARK: - Usage Examples

/*
 // Example usage throughout the app:
 
 // 1. API Service
 let apiService = LyoAPIService()
 apiService.configure(baseURL: LyoConfiguration.getBackendURL())
 
 // 2. WebSocket Service
 let wsService = LyoWebSocketService()
 wsService.configure(baseURL: LyoConfiguration.getWebSocketURL())
 
 // 3. Logging
 LyoConfiguration.log("User tapped Lyo button", level: .info)
 
 // 4. Feature Flags
 if LyoConfiguration.enableVoiceActivation {
     // Enable voice activation
 }
 
 // 5. Environment Detection
 if LyoConfiguration.isDebugMode {
     // Show debug information
 }
 */
