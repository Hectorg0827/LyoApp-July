//
//  DevelopmentConfig.swift
//  LyoApp
//
//  DEVELOPMENT MODE CONFIGURATION
//  This file provides optional development shortcuts for testing.
//  ⚠️ WARNING: Only use during development. Disable for production builds.
//

import Foundation

struct DevelopmentConfig {
    // MARK: - Development Flags
    
    /// Enable to skip authentication during development (FOR TESTING ONLY!)
    /// ⚠️ WARNING: Set to `false` for production builds!
    static let skipAuthentication: Bool = false
    
    /// Auto-login with test account on app launch (FOR TESTING ONLY!)
    /// ⚠️ WARNING: Set to `false` for production builds!
    static let autoLoginEnabled: Bool = false
    
    // MARK: - Test Account Credentials
    
    /// Test account email for development
    static let testEmail = "demo@lyoapp.com"
    
    /// Test account password for development
    static let testPassword = "Demo123!"
    
    // MARK: - Development Helpers
    
    /// Whether we're running in development mode
    static var isDevelopmentMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Check if development shortcuts are enabled
    static var shouldSkipAuth: Bool {
        return isDevelopmentMode && skipAuthentication
    }
    
    /// Check if auto-login is enabled
    static var shouldAutoLogin: Bool {
        return isDevelopmentMode && autoLoginEnabled
    }
    
    // MARK: - Validation
    
    /// Validate that development mode is properly configured
    static func validate() {
        #if !DEBUG
        // In release builds, ensure development features are disabled
        assert(!skipAuthentication, "❌ skipAuthentication MUST be false in production!")
        assert(!autoLoginEnabled, "❌ autoLoginEnabled MUST be false in production!")
        #endif
        
        if isDevelopmentMode {
            if skipAuthentication {
                print("⚠️ WARNING: Authentication bypass is ENABLED (development only)")
            }
            if autoLoginEnabled {
                print("⚠️ WARNING: Auto-login is ENABLED (development only)")
            }
        }
    }
}

// MARK: - Development-Only Extensions

extension AppState {
    /// Skip authentication for development testing
    /// ⚠️ WARNING: Only call this in development mode!
    func enableDevelopmentMode() {
        guard DevelopmentConfig.shouldSkipAuth else {
            print("❌ Development mode bypass is disabled")
            return
        }
        
        print("⚠️ Enabling development mode (authentication bypassed)")
        
        // Create a mock authenticated state for development
        self.isAuthenticated = true
        
        // Create a mock user for development
        self.currentUser = User(
            id: "dev_user_1",
            username: "dev_user",
            email: DevelopmentConfig.testEmail,
            fullName: "Development User",
            avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=dev",
            bio: "Development test user",
            followers: 0,
            following: 0,
            isVerified: false,
            xp: 0,
            level: 1,
            streak: 0,
            badges: ["Development"]
        )
        
        print("✅ Development mode enabled - authenticated as: \(currentUser?.username ?? "unknown")")
    }
    
    /// Auto-login with test credentials
    func performDevelopmentAutoLogin() async {
        guard DevelopmentConfig.shouldAutoLogin else {
            print("❌ Auto-login is disabled")
            return
        }
        
        print("🔐 Attempting auto-login with test credentials...")
        
        do {
            let response = try await APIClient.shared.login(
                email: DevelopmentConfig.testEmail,
                password: DevelopmentConfig.testPassword
            )
            
            await MainActor.run {
                self.setAuthTokens(
                    accessToken: response.actualAccessToken,
                    refreshToken: response.refreshToken ?? response.actualAccessToken,
                    userId: response.user.id
                )
                self.currentUser = response.user.toDomainUser()
                print("✅ Auto-login successful: \(response.user.username)")
            }
        } catch {
            print("❌ Auto-login failed: \(error.localizedDescription)")
        }
    }
}
