import Foundation

// MARK: - Production App Configuration
struct ProductionConfiguration {
    
    // MARK: - Environment Settings
    static let isProduction = true // Set to true for App Store builds
    static let enableAnalytics = true
    static let enableCrashReporting = true
    static let enableDebugLogging = !isProduction
    
    // MARK: - API Configuration
    static let baseAPIURL = "https://api.lyoapp.com/api/v1"
    static let apiTimeout: TimeInterval = 30.0
    static let maxRetryAttempts = 3
    
    // MARK: - AI Configuration
    static let enableGemmaAI = true
    static let gemmaModelName = "gemma-3n-7b"
    static let maxTokensPerRequest = 2048
    static let aiResponseTimeout: TimeInterval = 60.0
    
    // MARK: - Performance Settings
    static let enableImageCaching = true
    static let maxCacheSize: Int64 = 500 * 1024 * 1024 // 500MB
    static let enablePrefetching = true
    static let maxConcurrentDownloads = 3
    
    // MARK: - User Experience
    static let enableHaptics = true
    static let enableAnimations = true
    static let enableVoiceCommands = true
    static let defaultTheme: AppTheme = .dark
    
    // MARK: - Security Settings
    static let enableBiometricAuth = true
    static let tokenExpiryBuffer: TimeInterval = 300 // 5 minutes
    static let enableCertificatePinning = isProduction
    
    // MARK: - Feature Flags
    static let enableSocialFeatures = true
    static let enableOfflineMode = true
    static let enablePushNotifications = true
    static let enableAdvancedAnalytics = true
    
    // MARK: - App Store Information
    static let appStoreURL = "https://apps.apple.com/app/lyoapp"
    static let privacyPolicyURL = "https://www.lyoapp.com/privacy"
    static let termsOfServiceURL = "https://www.lyoapp.com/terms"
    static let supportEmail = "support@lyoapp.com"
}

// MARK: - App Theme
enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

// MARK: - Configuration Extensions
extension ProductionConfiguration {
    
    // MARK: - Build Information
    static var buildNumber: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    static var versionNumber: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.lyoapp.LyoApp"
    }
    
    // MARK: - Environment Detection
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Device Information
    static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            // UnicodeScalar(UInt8(value)) is non-optional; no need to force unwrap
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

// MARK: - Development vs Production Settings
extension ProductionConfiguration {
    
    static func configureForEnvironment() {
        if isProduction {
            #if DEBUG
            print("🚀 LyoApp configured for PRODUCTION")
            #endif
            // Disable debug features
            UserDefaults.standard.set(false, forKey: "debug_mode")
        } else {
            #if DEBUG
            print("🛠 LyoApp configured for DEVELOPMENT")
            #endif
            // Enable debug features
            UserDefaults.standard.set(true, forKey: "debug_mode")
        }
        
        #if DEBUG
        print("📱 Device: \(deviceModel)")
        print("📦 Version: \(versionNumber) (\(buildNumber))")
        print("🌐 API Base: \(baseAPIURL)")
        print("🧠 AI Enabled: \(enableGemmaAI)")
        #endif
    }
}
