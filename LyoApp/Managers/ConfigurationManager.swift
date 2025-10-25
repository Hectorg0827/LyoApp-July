import Foundation

// MARK: - Configuration Manager
class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private init() {}
    
    // MARK: - Environment Configuration
    enum Environment {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "http://127.0.0.1:8000"
            case .staging:
                return "https://staging-api.lyoapp.com"
            case .production:
                return "https://api.lyoapp.com"
            }
        }
        
        var websocketURL: String {
            switch self {
            case .development:
                return "ws://127.0.0.1:8000/ws"
            case .staging:
                return "wss://staging-api.lyoapp.com/ws"
            case .production:
                return "wss://api.lyoapp.com/ws"
            }
        }
        
        var enableLogging: Bool {
            switch self {
            case .development:
                return true
            case .staging:
                return true
            case .production:
                return false
            }
        }
    }
    
    // MARK: - Current Environment
    var currentEnvironment: Environment {
        #if DEBUG
        return .development
        #else
        // Check build configuration or use production as default
        if let buildConfig = Bundle.main.object(forInfoDictionaryKey: "BuildConfiguration") as? String {
            switch buildConfig.lowercased() {
            case "staging":
                return .staging
            default:
                return .production
            }
        }
        return .production
        #endif
    }
    
    // MARK: - API Configuration
    var baseURL: String {
        return currentEnvironment.baseURL
    }
    
    var websocketURL: String {
        return currentEnvironment.websocketURL
    }
    
    // MARK: - Feature Flags
    var enableBiometricAuth: Bool {
        return true
    }
    
    var enablePushNotifications: Bool {
        return true
    }
    
    var enableAnalytics: Bool {
        return currentEnvironment != .development
    }
    
    var enableCrashReporting: Bool {
        return currentEnvironment == .production
    }
    
    // MARK: - App Configuration
    var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    // MARK: - Cache Configuration
    var cacheExpirationTime: TimeInterval {
        return 24 * 60 * 60 // 24 hours
    }
    
    var maxCacheSize: Int {
        return 100 * 1024 * 1024 // 100MB
    }
    
    // MARK: - Network Configuration
    var requestTimeout: TimeInterval {
        return 30.0
    }
    
    var maxRetryAttempts: Int {
        return 3
    }
    
    // MARK: - Logging
    func log(_ message: String, level: LogLevel = .info) {
        if currentEnvironment.enableLogging {
            let timestamp = DateFormatter.iso8601.string(from: Date())
            print("[\(timestamp)] [\(level.rawValue.uppercased())] \(message)")
        }
    }
}

// MARK: - Log Level
enum LogLevel: String, CaseIterable {
    case debug
    case info
    case warning
    case error
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
