import Foundation

// MARK: - API Configuration
struct APIConfig {
    // Backend URLs for different environments
    static let developmentURL = "http://localhost:8000/api/v1"
    static let stagingURL = "https://staging-api.lyoapp.com/api/v1"
    static let productionURL = "https://lyo-backend-830162750094.us-central1.run.app/api/v1"
    
    // Current environment
    #if DEBUG
    static let baseURL = developmentURL
    static let isProduction = false
    #else
    static let baseURL = productionURL
    static let isProduction = true
    #endif
    
    // Request timeouts
    static let requestTimeout: TimeInterval = 30.0
    static let uploadTimeout: TimeInterval = 60.0
    
    // WebSocket configuration
    #if DEBUG
    static let webSocketURL = "ws://localhost:8000/api/v1/ws"
    #else
    static let webSocketURL = "wss://api.lyoapp.com/api/v1/ws"
    #endif
}

// MARK: - Development Configuration
struct DevelopmentConfig {
    // Set to false when backend is running and ready
    static let useMockData = false
    
    // Show development indicators in UI - disabled for production
    #if DEBUG
    static let showDevelopmentIndicators = true
    #else
    static let showDevelopmentIndicators = false
    #endif
    
    // Debug logging - disabled for production
    #if DEBUG
    static let enableDebugLogging = true
    #else
    static let enableDebugLogging = false
    #endif
    
    // Test credentials for minimal backend
    static let testEmail = "admin@lyoapp.com"
    static let testPassword = "admin123"
}

// MARK: - API Error Types
// APIError is defined in AIAvatarIntegration.swift to avoid duplication
