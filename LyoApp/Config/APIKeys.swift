import Foundation

struct APIKeys {
    // Backend Configuration
    #if DEBUG
    static let baseURL = "http://localhost:8002"
    static let webSocketURL = "ws://localhost:8002/ws"
    #else
    static let baseURL = "https://api.lyoapp.com"
    static let webSocketURL = "wss://api.lyoapp.com/ws"
    #endif
    
    // Third-party API Keys (Replace with actual keys)
    static let youtubeAPIKey = "YOUR_YOUTUBE_API_KEY"
    static let googleBooksAPIKey = "YOUR_GOOGLE_BOOKS_API_KEY"
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY"
    static let courseraAPIKey = "YOUR_COURSERA_API_KEY"
    
    // App Configuration
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // Features Flags
    #if DEBUG
    static let isDebugMode = true
    static let enableLogging = true
    #else
    static let isDebugMode = false
    static let enableLogging = false
    #endif
    // Mock data configuration - disabled for production
    static let enableMockData = false
    
    // URLs
    static let privacyPolicyURL = "https://www.lyoapp.com/privacy"
    static let termsOfServiceURL = "https://www.lyoapp.com/terms"
    static let supportURL = "https://www.lyoapp.com/support"
}