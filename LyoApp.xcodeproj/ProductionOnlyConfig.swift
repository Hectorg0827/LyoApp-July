import Foundation

/// PRODUCTION-ONLY CONFIGURATION
/// This ensures 100% real backend connectivity with zero demo mode possibility
public struct ProductionOnlyConfig {
    
    // MARK: - PRODUCTION BACKEND - GOOGLE CLOUD RUN
    public static let API_BASE_URL = "https://lyo-backend-830162750094.us-central1.run.app"
    public static let WEBSOCKET_URL = "wss://lyo-backend-830162750094.us-central1.run.app"
    
    // MARK: - FORCE PRODUCTION MODE
    public static let IS_PRODUCTION = true
    public static let USE_MOCK_DATA = false
    public static let ALLOW_DEMO_MODE = false
    public static let ENVIRONMENT = "PRODUCTION"
    
    // MARK: - API ENDPOINTS (REAL BACKEND ONLY)
    public struct Endpoints {
        static let health = "/health"
        static let v1 = "/v1"
        static let login = "/v1/auth/login"
        static let register = "/v1/auth/register"
        static let refreshToken = "/v1/auth/refresh"
        static let logout = "/v1/auth/logout"
        static let feed = "/v1/feed"
        static let aiChat = "/v1/ai/chat"
        static let userProfile = "/v1/users/me"
        static let uploadMedia = "/v1/media/upload"
        static let websocketAI = "/ai/ws"
    }
    
    // MARK: - VALIDATION - CRASHES IF NOT PRODUCTION
    public static func validate() {
        guard API_BASE_URL.contains("lyo-backend-830162750094") else {
            fatalError("❌ FATAL: Not pointing to production Google Cloud Run backend!")
        }
        
        guard !USE_MOCK_DATA else {
            fatalError("❌ FATAL: Mock data is enabled! This must be false!")
        }
        
        guard IS_PRODUCTION else {
            fatalError("❌ FATAL: Not in production mode!")
        }
        
        print("✅ Production Configuration Validated")
        print("🌐 Backend: \(API_BASE_URL)")
        print("🚫 Mock Data: DISABLED")
        print("🔒 Demo Mode: IMPOSSIBLE")
    }
    
    // MARK: - GET URLS
    public static func getBaseURL() -> URL {
        validate()
        return URL(string: API_BASE_URL)!
    }
    
    public static func getV1URL() -> URL {
        return getBaseURL().appendingPathComponent("v1")
    }
    
    public static func getWebSocketURL() -> URL {
        return URL(string: WEBSOCKET_URL)!
    }
    
    // MARK: - PREVENT NON-PRODUCTION ACCESS
    public static func blockNonProductionAccess() {
        let blockedHosts = ["localhost", "127.0.0.1", "staging", "dev", "mock"]
        for host in blockedHosts {
            if API_BASE_URL.contains(host) {
                fatalError("❌ FATAL: Blocked non-production host: \(host)")
            }
        }
    }
}