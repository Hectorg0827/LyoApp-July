import Foundation

struct APIKeys {
    // Backend Configuration
    static let baseURL = "http://localhost:8002"
    static let webSocketURL = "ws://localhost:8002/ws"
    
    // Third-party API Keys (Replace with actual keys)
    static let youtubeAPIKey = "YOUR_YOUTUBE_API_KEY"
    static let googleBooksAPIKey = "YOUR_GOOGLE_BOOKS_API_KEY"
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY"
    static let courseraAPIKey = "YOUR_COURSERA_API_KEY"
    
    // App Configuration
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // Features Flags
    static let isDebugMode = true
    static let enableLogging = true
    static let enableMockData = true
    
    // URLs
    static let privacyPolicyURL = "https://example.com/privacy"
    static let termsOfServiceURL = "https://example.com/terms"
    static let supportURL = "https://example.com/support"
}