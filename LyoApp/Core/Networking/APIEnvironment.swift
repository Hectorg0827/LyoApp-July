import Foundation

/// Environment configuration for the Lyo API
enum APIEnvironment {
    case development  // Local LyoBackendJune
    case prod        // Production cloud backend
    
    /// Base URL for the environment
    var base: URL {
        switch self {
        case .development:
            return URL(string: "http://localhost:8000")!  // Local LyoBackendJune
        case .prod:
            return URL(string: "https://lyo-backend-830162750094.us-central1.run.app")!
        }
    }
    
    /// Versioned API URL (v1)
    var v1: URL {
        return base.appendingPathComponent("v1")
    }
    
    /// WebSocket base URL
    var webSocketBase: URL {
        switch self {
        case .development:
            return URL(string: "ws://localhost:8000")!   // Local LyoBackendJune WebSocket
        case .prod:
            return URL(string: "wss://lyo-backend-830162750094.us-central1.run.app")!
        }
    }
    
    /// Environment display name
    var displayName: String {
        switch self {
        case .development: return "🛠️ Local LyoBackendJune"
        case .prod: return "☁️ Production"
        }
    }
}

// MARK: - Current Environment Configuration
extension APIEnvironment {
    /// Current environment - automatically detects based on build configuration and environment variables
    static var current: APIEnvironment {
        // Check for environment variable override first
        if let envVar = ProcessInfo.processInfo.environment["LYO_ENV"] {
            switch envVar.lowercased() {
            case "production", "prod":
                print("🔒 APIEnvironment.current: PRODUCTION MODE (ENV VAR)")
                print("🌐 URL: https://lyo-backend-830162750094.us-central1.run.app")
                return .prod
            case "development", "dev", "local":
                print("🛠️ APIEnvironment.current: LOCAL DEVELOPMENT MODE (ENV VAR)")
                print("🌐 URL: http://localhost:8000 (LyoBackendJune)")
                return .development
            default:
                break
            }
        }
        
        // Default behavior: ALWAYS use production (changed for easy deployment)
        // If you need local backend, set LYO_ENV=dev in environment variables
        #if DEBUG
        let env = APIEnvironment.prod  // Changed to production by default!
        print("� APIEnvironment.current: PRODUCTION MODE (Default)")
        print("🌐 URL: https://lyo-backend-830162750094.us-central1.run.app")
        print("💡 Tip: Set LYO_ENV=dev to use local backend")
        #else
        let env = APIEnvironment.prod
        print("🔒 APIEnvironment.current: PRODUCTION MODE")
        print("🌐 URL: https://lyo-backend-830162750094.us-central1.run.app")
        #endif
        return env
    }
    
    /// Helper to check if we're using local backend
    static var isLocal: Bool {
        return current == .development
    }
}
