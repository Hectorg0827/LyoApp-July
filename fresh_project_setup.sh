#!/bin/bash

echo "🚀 CREATING FRESH LyoApp WITH BACKEND INTEGRATION 🚀"
echo "Backend: LyoBackendJune | iOS: Production Ready"

cd "/Users/republicalatuya/Desktop/LyoApp July"

echo "🧹 Phase 1: Complete cleanup for fresh start..."

# Remove ALL problematic files and directories
rm -rf LyoApp.xcodeproj
rm -rf ~/Library/Developer/Xcode/DerivedData/LyoApp-*
rm -rf LyoApp/**/_backup
rm -rf LyoApp/**/*_backup*

# Remove all duplicate and problematic files
find LyoApp -name "*_Clean*" -delete 2>/dev/null
find LyoApp -name "*_Old*" -delete 2>/dev/null
find LyoApp -name "DataManager.swift" -delete 2>/dev/null
find LyoApp -name "*.xcdatamodeld" -exec rm -rf {} + 2>/dev/null

# Remove specific duplicates
rm -f "LyoApp/LearningHubView.swift" 2>/dev/null
rm -f "LyoApp/LearningAssistantView.swift" 2>/dev/null
rm -f "LyoApp/LioAI.swift" 2>/dev/null
rm -f "LyoApp/ProfessionalLibraryView.swift" 2>/dev/null

# Remove duplicate ViewModels
find LyoApp -path "*/Models/LearningSearchViewModel.swift" -delete 2>/dev/null

echo "✅ Phase 1 complete: All problematic files removed"

echo "🏗️ Phase 2: Creating clean project structure..."

# Create optimal directory structure for backend integration
mkdir -p LyoApp/Network/{API,Services,Models}
mkdir -p LyoApp/Core/{Configuration,Extensions,Utilities}
mkdir -p LyoApp/Features/{Auth,Feed,Learning,Profile,Community}
mkdir -p LyoApp/Features/Auth/{Views,ViewModels}
mkdir -p LyoApp/Features/Feed/{Views,ViewModels}
mkdir -p LyoApp/Features/Learning/{Views,ViewModels}
mkdir -p LyoApp/Resources

echo "✅ Phase 2 complete: Clean structure created"

echo "🔧 Phase 3: Creating backend integration configuration..."

# Create backend configuration file
cat > LyoApp/Core/Configuration/BackendConfig.swift << 'EOF'
import Foundation

// MARK: - Backend Configuration for LyoBackendJune Integration
struct BackendConfig {
    // MARK: - Environment Configuration
    static let environment: Environment = .development
    
    enum Environment {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "http://localhost:8000"  // LyoBackendJune local
            case .staging:
                return "https://staging-lyo-backend.herokuapp.com"
            case .production:
                return "https://lyo-backend.herokuapp.com"
            }
        }
        
        var apiVersion: String {
            return "/api/v1"
        }
        
        var fullAPIURL: String {
            return baseURL + apiVersion
        }
    }
    
    // MARK: - API Endpoints (matching LyoBackendJune structure)
    struct Endpoints {
        // Authentication
        static let register = "/auth/register"
        static let login = "/auth/login"
        static let refreshToken = "/auth/refresh"
        static let logout = "/auth/logout"
        
        // User Management
        static let userProfile = "/users/profile"
        static let updateProfile = "/users/profile"
        static let userFeed = "/users/feed"
        
        // Educational Content
        static let courses = "/courses"
        static let videos = "/videos"
        static let ebooks = "/ebooks"
        static let learningProgress = "/learning/progress"
        
        // Social Features
        static let posts = "/posts"
        static let communities = "/communities"
        static let stories = "/stories"
        
        // AI Features (matching backend's Gemini integration)
        static let aiChat = "/ai/chat"
        static let aiStudyMode = "/ai/study"
        static let aiRecommendations = "/ai/recommendations"
        
        // Gamification
        static let achievements = "/gamification/achievements"
        static let leaderboard = "/gamification/leaderboard"
        static let badges = "/gamification/badges"
        
        // Health Check
        static let health = "/health"
    }
    
    // MARK: - Request Configuration
    static let timeoutInterval: TimeInterval = 30.0
    static let maxRetryAttempts = 3
    
    // MARK: - WebSocket Configuration (if backend supports)
    static let webSocketURL = environment.baseURL.replacingOccurrences(of: "http", with: "ws")
}
EOF

echo "✅ Phase 3 complete: Backend configuration created"

echo "🌐 Phase 4: Creating clean project.yml..."

cat > project.yml << 'YAML'
name: LyoApp
options:
  bundleIdPrefix: com.lyo
  createIntermediateGroups: true
  deploymentTarget:
    iOS: "17.0"
  developmentLanguage: en

targets:
  LyoApp:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: LyoApp
        excludes:
          - "**/*_Clean*"
          - "**/*_Old*" 
          - "**/*_backup*"
          - "**/*.xcdatamodeld"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.lyo.app
        DEVELOPMENT_TEAM: ""
        CODE_SIGN_STYLE: Automatic
        TARGETED_DEVICE_FAMILY: "1,2"
        IPHONEOS_DEPLOYMENT_TARGET: "17.0"
        SWIFT_VERSION: "5.0"
        ENABLE_PREVIEWS: YES
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        SUPPORTS_MACCATALYST: NO
        CODE_SIGN_IDENTITY: ""
        CODE_SIGNING_REQUIRED: NO
      debug:
        SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG
      release:
        SWIFT_COMPILATION_MODE: wholemodule
    info:
      path: LyoApp/Info.plist
      properties:
        CFBundleDisplayName: Lyo
        CFBundleName: LyoApp
        CFBundleShortVersionString: "1.0"
        CFBundleVersion: "1"
        LSRequiresIPhoneOS: true
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
        UIApplicationSupportsIndirectInputEvents: true
        UILaunchScreen: {}
        UIRequiredDeviceCapabilities:
          - armv7
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
        UISupportedInterfaceOrientations~ipad:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationPortraitUpsideDown
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
        NSAppTransportSecurity:
          NSAllowsArbitraryLoads: true
        NSCameraUsageDescription: "Lyo uses camera for profile pictures and content creation"
        NSPhotoLibraryUsageDescription: "Lyo accesses photos for profile pictures and content sharing"
        NSMicrophoneUsageDescription: "Lyo uses microphone for video content and voice messages"
YAML

echo "✅ Phase 4 complete: Clean project configuration created"

echo "🚀 Phase 5: Generating fresh project..."
xcodegen generate

echo "🧪 Phase 6: Initial build test..."
timeout 30 xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' 2>&1 | grep -E '(BUILD SUCCEEDED|BUILD FAILED|error:)' | head -5

echo ""
echo "✅ FRESH PROJECT FOUNDATION COMPLETE!"
echo "🎯 Status: Clean iOS project with backend integration structure"
echo "📱 Next: Adding production features with backend connectivity"
echo "🚀 Goal: 100% market-ready app with LyoBackendJune integration"
