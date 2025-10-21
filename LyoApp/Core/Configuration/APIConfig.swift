import Foundation

// MARK: - Production-Only Configuration (No Demo Mode Allowed)
// Centralized configuration derived from BackendConfig

// MARK: - Legacy API Config Compatibility
/// Maintains compatibility with existing APIConfig usage while using APIEnvironment as source of truth
struct APIConfig {
    static var baseURL: String {
        return APIEnvironment.current.base.absoluteString
    }

    static var webSocketURL: String {
        return APIEnvironment.current.webSocketBase.absoluteString
    }

    enum LegacyEnvironment {
        case local
        case staging
        case prod

        var displayName: String {
            // Since APIEnvironment only has production, map everything to production
            return APIEnvironment.current.displayName
        }
    }

    static var currentEnvironment: LegacyEnvironment {
        // Always return production since APIEnvironment is production-only
        return .prod
    }

    static var useLocalBackend: Bool { false } // Production only
    static var cloudURL: String { APIEnvironment.current.base.absoluteString }
    static var localURL: String { APIEnvironment.current.base.absoluteString } // Same as cloud for production-only

    static let requestTimeout: TimeInterval = 30.0
    static let uploadTimeout: TimeInterval = 60.0

    static var currentBackend: String {
        return currentEnvironment.displayName
    }
}

// MARK: - Development Config Compatibility
struct DevelopmentConfig {
    static let useMockData = false
    static let showDevelopmentIndicators = false // Production only
    static let enableDebugLogging = false // Production only

    // Test credentials for backend testing
    static let testEmail = "admin@lyoapp.com"
    static let testPassword = "admin123"
}
