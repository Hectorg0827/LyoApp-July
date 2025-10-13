import Foundation

/// Application configuration derived from `BackendConfig`.
/// Demo/mock modes remain disabled, but the backend host can be switched by updating
/// `BackendConfig.environment` in one place.
struct AppConfig {
    // MARK: - Environment Settings
    static var currentEnvironment: Environment {
        get {
            // Clear legacy overrides so the single source of truth is respected
            UserDefaults.standard.removeObject(forKey: "app_environment")
            UnifiedLyoConfig.validateConfiguration()
            return Environment(backend: BackendConfig.environment)
        }
        set {
            print("ℹ️ Environment changes are controlled via BackendConfig.environment (ignoring request for \(newValue.rawValue)).")
        }
    }

    enum Environment: String, Codable {
        case local
        case staging
        case production

        init(backend: BackendConfig.Environment) {
            switch backend {
            case .development: self = .local
            case .staging: self = .staging
            case .production: self = .production
            }
        }

        fileprivate var backendEnvironment: BackendConfig.Environment {
            switch self {
            case .local: return .development
            case .staging: return .staging
            case .production: return .production
            }
        }

        var displayName: String { backendEnvironment.displayName }
        var baseURL: String { backendEnvironment.baseURL }
        var fullAPIURL: String { backendEnvironment.fullAPIURL }
        var usesMockData: Bool { false }

        var enableDebugLogging: Bool {
            backendEnvironment == .development
        }

        var enableAnalytics: Bool { true }
    }

    // MARK: - Quick Access Properties
    static var isProduction: Bool { BackendConfig.environment == .production }
    static var isDevelopment: Bool { BackendConfig.environment == .development }
    static var isDemo: Bool { false }
    static var usesMockData: Bool { false }

    // MARK: - API Configuration
    static var apiBaseURL: String { APIConfig.baseURL }
    static var apiFullURL: String { BackendConfig.environment.fullAPIURL }
    static var enableDebugLogging: Bool { currentEnvironment.enableDebugLogging }
    static var enableAnalytics: Bool { currentEnvironment.enableAnalytics }

    // MARK: - Environment Switching Helpers
    static func switchToEnvironment(_ environment: Environment) {
        print("ℹ️ To change environments, update BackendConfig.environment (currently \(BackendConfig.environment.displayName)).")
        if environment != currentEnvironment {
            print("   Requested environment \(environment.displayName) ignored to keep configuration consistent.")
        }
    }

    static func switchToProduction() {
        switchToEnvironment(.production)
    }

    static func switchToDevelopment() {
        switchToEnvironment(.local)
    }

    static func switchToDemo() {
        print("🚫 Demo mode is permanently disabled.")
        fatalError("❌ Demo mode is not supported in this build.")
    }

    // MARK: - Cache Management
    private static func clearAppCache() {
        UserDefaults.standard.removeObject(forKey: "lyo_access_token")
        UserDefaults.standard.removeObject(forKey: "lyo_refresh_token")
        UserDefaults.standard.removeObject(forKey: "lyo_user_id")
        URLCache.shared.removeAllCachedResponses()
        print("🧹 App cache cleared")
    }

    // MARK: - Debug Information
    static func printCurrentConfiguration() {
        print("📱 === LyoApp Configuration ===")
        print("🌍 Environment: \(currentEnvironment.displayName)")
        print("🌐 API Base URL: \(apiBaseURL)")
        print("🔗 Full API URL: \(apiFullURL)")
        print("📊 Mock Data: ❌ Disabled")
        print("🔍 Debug Logging: \(enableDebugLogging ? \"✅ Enabled\" : \"❌ Disabled\")")
        print("📈 Analytics: \(enableAnalytics ? \"✅ Enabled\" : \"❌ Disabled\")")
        print("==============================")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let environmentChanged = Notification.Name("AppConfig.environmentChanged")
}

// MARK: - Legacy Configuration Compatibility
extension AppConfig {
    static var useLocalBackend: Bool {
        BackendConfig.isLocalEnvironment
    }

    static var cloudURL: String {
        BackendConfig.Environment.production.baseURL
    }

    static var localURL: String {
        BackendConfig.Environment.development.baseURL
    }
}