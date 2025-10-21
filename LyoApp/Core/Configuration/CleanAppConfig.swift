import Foundation

// MARK: - Clean App Configuration Template
// This provides a clean, easy-to-understand environment switching system

struct CleanAppConfig {
    
    // MARK: - Environment Types
    enum Environment: String, CaseIterable {
        case demo = "demo"
        case staging = "staging" 
        case production = "production"
        
        var displayName: String {
            switch self {
            case .demo: return "Demo"
            case .staging: return "Staging"
            case .production: return "Production"
            }
        }
        
        var baseURL: String {
            switch self {
            case .demo:
                return "mock://demo.local" // Mock data only
            case .staging:
                return "https://lyo-backend-staging-830162750094.us-central1.run.app"
            case .production:
                return "https://lyo-backend-830162750094.us-central1.run.app" // Your Cloud Run backend
            }
        }
        
        var apiPath: String {
            switch self {
            case .demo:
                return "" // No API path for mock
            case .staging, .production:
                return "/api/v1"
            }
        }
        
        var fullAPIURL: String {
            return baseURL + apiPath
        }
        
        var usesMockData: Bool {
            return self == .demo
        }
        
        var enableDebugLogging: Bool {
            return self != .production
        }
    }
    
    // MARK: - Current Environment
    static var currentEnvironment: Environment {
        get {
            // 1. Check UserDefaults for manual override (for debugging)
            if let envString = UserDefaults.standard.string(forKey: "lyo_forced_environment"),
               let env = Environment(rawValue: envString) {
                print("🔧 Using forced environment: \(env.displayName)")
                return env
            }
            
            // 2. Check for compile-time environment flags
            #if DEMO
            return .demo
            #elseif STAGING
            return .staging
            #elseif PRODUCTION
            return .production
            #else
            // 3. Default based on build configuration
            #if DEBUG
            return .production  // 🎯 Use production backend even for debug builds
            #else
            return .production  // Always production for release
            #endif
            #endif
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "lyo_forced_environment")
            print("🔄 Environment manually switched to: \(newValue.displayName)")
            NotificationCenter.default.post(name: .environmentChanged, object: newValue)
        }
    }
    
    // MARK: - Quick Access Properties
    static var apiBaseURL: String { currentEnvironment.fullAPIURL }
    static var isProduction: Bool { currentEnvironment == .production }
    static var isDemo: Bool { currentEnvironment == .demo }
    static var usesMockData: Bool { currentEnvironment.usesMockData }
    static var enableDebugLogging: Bool { currentEnvironment.enableDebugLogging }
    
    // MARK: - Environment Switching (Debug Only)
    #if DEBUG
    static func forceEnvironment(_ environment: Environment) {
        currentEnvironment = environment
    }
    
    static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: "lyo_forced_environment")
        print("🔄 Environment reset to default")
    }
    
    static func switchToProduction() { forceEnvironment(.production) }
    static func switchToStaging() { forceEnvironment(.staging) }
    static func switchToDemo() { forceEnvironment(.demo) }
    #endif
    
    // MARK: - Configuration Display
    static func printConfiguration() {
        print("🚀 === LyoApp Environment Configuration ===")
        print("📱 Environment: \(currentEnvironment.displayName)")
        print("🌐 API URL: \(apiBaseURL)")
        print("🎭 Mock Data: \(usesMockData ? "✅ Enabled" : "❌ Disabled")")
        print("🔍 Debug Logging: \(enableDebugLogging ? "✅ Enabled" : "❌ Disabled")")
        print("⚙️  Build Config: \(isDebugBuild ? "Debug" : "Release")")
        print("==========================================")
    }
    
    // MARK: - Build Information
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var buildConfiguration: String {
        return isDebugBuild ? "Debug" : "Release"
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let environmentChanged = Notification.Name("CleanAppConfig.environmentChanged")
}

// MARK: - Usage Examples
/*
 
 // In your app initialization:
 CleanAppConfig.printConfiguration()
 
 // For API calls:
 let apiURL = CleanAppConfig.apiBaseURL
 
 // For environment switching in debug builds:
 #if DEBUG
 CleanAppConfig.switchToDemo()     // Switch to mock data
 CleanAppConfig.switchToProduction() // Switch to Cloud Run backend
 #endif
 
 // Check current state:
 if CleanAppConfig.isProduction {
     // Production-specific code
 }
 
 if CleanAppConfig.usesMockData {
     // Show demo UI elements
 }
 
 */