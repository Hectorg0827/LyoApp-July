import Foundation

struct APIKeys {
    // Backend Configuration (using APIEnvironment as single source of truth)
    static let baseURL: String = APIEnvironment.current.base.absoluteString
    // WebSocket URL from APIEnvironment
    static let webSocketURL: String = APIEnvironment.current.webSocketBase.absoluteString
    
    // Third-party API Keys (Replace with actual keys)
    static let youtubeAPIKey = "YOUR_YOUTUBE_API_KEY"
    static let googleBooksAPIKey = "YOUR_GOOGLE_BOOKS_API_KEY"
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY"
    static let courseraAPIKey = "YOUR_COURSERA_API_KEY"
    
    // MARK: - Google Gemini API Key Configuration
    static var geminiAPIKey: String {
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["GEMINI_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        return "AIzaSyAXqRkBk_PUuiy8WKCQ66v447NmTE_tCK0"
    }
    
    static var isGeminiAPIKeyConfigured: Bool {
        let key = geminiAPIKey
        return !key.isEmpty &&
               !key.contains("YOUR_") &&
               !key.contains("PLACEHOLDER") &&
               key.count > 20
    }
    
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
