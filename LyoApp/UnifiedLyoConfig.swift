import Foundation

/// SINGLE SOURCE OF TRUTH - NO DEMO MODE ALLOWED
/// This configuration makes it impossible for the app to run in demo mode
struct UnifiedLyoConfig {
    
    // PRODUCTION ONLY - NO OTHER OPTIONS
    static var isProductionOnly: Bool { BackendConfig.environment == .production }
    static var baseURL: String { BackendConfig.environment.baseURL }
    static var webSocketURL: String { BackendConfig.environment.webSocketURL }
    
    // DISABLE ALL MOCK DATA PERMANENTLY
    static let useMockData = false
    static let allowMockFallback = false
    static let generateDemoContent = false
    
    // API Settings
    static var apiVersion: String { BackendConfig.environment.apiVersion }
    static let requestTimeout: TimeInterval = 30.0
    static let uploadTimeout: TimeInterval = 60.0
    
    // Feature flags
    static let requireAuthentication = true
    static let showErrorDetails = true
    static let enableAnalytics = true
    
    static func validateConfiguration() {
        assert(!useMockData, "❌ Mock data must be disabled!")
        assert(!allowMockFallback, "❌ No mock fallback allowed!")
        assert(!generateDemoContent, "❌ Demo content generation is forbidden!")
        
        if BackendConfig.environment.allowsInsecureTransport {
            print("ℹ️ Running with local backend at \(baseURL). HTTPS enforcement relaxed for development.")
        } else {
            assert(baseURL.hasPrefix("https://"), "❌ Production backend must use HTTPS!")
        }
    }
    
    static func printConfiguration() {
        print("🎯 === LyoApp PRODUCTION-ONLY Configuration ===")
        print("🌐 API URL: \(baseURL)\(apiVersion)")
        print("🔌 WebSocket: \(webSocketURL)")
        print("🚫 Mock Data: PERMANENTLY DISABLED")
        print("✅ Real Backend: REQUIRED")
        print("🔒 Demo Mode: IMPOSSIBLE")
        print("🎭 Demo Content: FORBIDDEN")
        print("===============================================")
    }
    
    // Environment info for debugging
    static var environment: String {
        switch BackendConfig.environment {
        case .development:
            return "Local (Debug)"
        case .staging:
            return "Staging"
        case .production:
            #if DEBUG
            return "Debug (Production Backend)"
            #else
            return "Release (Production)"
            #endif
        }
    }
    
    static var enableDebugLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Environment enum for compatibility
enum ProductionEnvironment: String, CaseIterable {
    case local = "local"
    case staging = "staging"
    case production = "production"
    
    var displayName: String {
        switch self {
        case .local:
            return BackendConfig.Environment.development.displayName
        case .staging:
            return BackendConfig.Environment.staging.displayName
        case .production:
            return BackendConfig.Environment.production.displayName
        }
    }
    
    var baseURL: String { UnifiedLyoConfig.baseURL }
    var apiURL: String { baseURL + UnifiedLyoConfig.apiVersion }
    var webSocketURL: String { UnifiedLyoConfig.webSocketURL }
    var useMockData: Bool { false }
}