import Foundation

// MARK: - API Configuration
struct APIConfig {
    // Backend URLs for different environments
    static let developmentURL = "http://localhost:8000/api/v1"
    static let stagingURL = "https://staging-api.lyo.ai/api/v1"
    static let productionURL = "https://api.lyo.ai/api/v1"
    
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
    static let webSocketURL = "ws://localhost:8000/api/v1/ws"
}

// MARK: - Development Configuration
struct DevelopmentConfig {
    // Set to false when backend is running and ready
    static let useMockData = false
    
    // Show development indicators in UI
    static let showDevelopmentIndicators = true
    
    // Debug logging
    static let enableDebugLogging = true
    
    // Test credentials for minimal backend
    static let testEmail = "admin@lyo.ai"
    static let testPassword = "admin123"
}

// MARK: - API Error Types
// APIError is defined in AIAvatarIntegration.swift to avoid duplication