import Foundation

/// Environment configuration for the Lyo API
enum APIEnvironment {
    case dev
    case staging 
    case prod
    
    /// Base URL for the environment
    var base: URL {
        switch self {
        case .dev:
            return URL(string: "https://api.dev.lyo.app")!
        case .staging:
            return URL(string: "https://api.staging.lyo.app")!
        case .prod:
            return URL(string: "https://api.lyo.app")!
        }
    }
    
    /// Versioned API URL (v1)
    var v1: URL {
        return base.appendingPathComponent("v1")
    }
    
    /// WebSocket base URL
    var webSocketBase: URL {
        switch self {
        case .dev:
            return URL(string: "wss://api.dev.lyo.app")!
        case .staging:
            return URL(string: "wss://api.staging.lyo.app")!
        case .prod:
            return URL(string: "wss://api.lyo.app")!
        }
    }
    
    /// Current environment based on build configuration
    static var current: APIEnvironment {
        #if DEBUG
        return .dev
        #else
        return .prod
        #endif
    }
    
    /// Environment display name
    var displayName: String {
        switch self {
        case .dev: return "Development"
        case .staging: return "Staging"
        case .prod: return "Production"
        }
    }
}