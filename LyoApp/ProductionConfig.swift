import Foundation

/// Production Configuration for LyoApp
struct ProductionConfig {
    
    // MARK: - Backend Configuration
    #if DEBUG
    static let apiBaseURL = "http://localhost:8000/api/v1"
    static let webSocketURL = "ws://localhost:8000/api/v1/ws"
    static let isProduction = false
    #else
    static let apiBaseURL = "https://api.lyoapp.com/api/v1"
    static let webSocketURL = "wss://api.lyoapp.com/api/v1/ws"
    static let isProduction = true
    #endif
    
    // MARK: - App Configuration
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Feature Flags
    static let enableAnalytics = isProduction
    static let enableCrashReporting = isProduction
    static let enableDebugLogging = !isProduction
    
    // MARK: - API Configuration
    static let requestTimeout: TimeInterval = 30.0
    static let maxRetryAttempts = 3
    
    // MARK: - Security Configuration
    static let enableSSLPinning = isProduction
    static let requireDeviceAuthentication = isProduction
    
    // MARK: - Performance Configuration
    static let cacheExpirationTime: TimeInterval = isProduction ? 3600 : 300 // 1 hour in prod, 5 min in dev
    static let maxConcurrentRequests = 10
    
    // MARK: - Methods
    static func getAPIBaseURL() -> String {
        return apiBaseURL
    }
    
    static func getWebSocketURL() -> String {
        return webSocketURL
    }
    
    static func shouldUseMockData() -> Bool {
        return !isProduction && LyoConfiguration.enableMockData
    }
}
