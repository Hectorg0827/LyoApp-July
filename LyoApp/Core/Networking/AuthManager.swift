import Foundation
import Security

/// Authentication manager with JWT refresh token flow
actor AuthManager {
    // MARK: - Properties
    private var accessToken: String?
    private var refreshToken: String?
    private var isRefreshing = false
    private let keychain = AuthKeychainManager()
    
    // Keys for keychain storage
    private let accessTokenKey = "lyo_access_token"
    private let refreshTokenKey = "lyo_refresh_token"
    
    // MARK: - Initialization
    init() {
        Task {
            await loadTokensFromKeychain()
        }
    }
    
    // MARK: - Token Management
    
    /// Set tokens and store securely in keychain
    func setTokens(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
        
        // Store securely in keychain
        keychain.save(access, forKey: accessTokenKey)
        keychain.save(refresh, forKey: refreshTokenKey)
        
        print("🔐 Tokens stored securely")
    }
    
    /// Load tokens from keychain on app launch
    private func loadTokensFromKeychain() {
        accessToken = keychain.load(key: accessTokenKey)
        refreshToken = keychain.load(key: refreshTokenKey)
        
        if accessToken != nil && refreshToken != nil {
            print("🔓 Tokens loaded from keychain")
        } else {
            print("📝 No tokens found in keychain")
        }
    }
    
    /// Clear all tokens
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        
        keychain.delete(key: accessTokenKey)
        keychain.delete(key: refreshTokenKey)
        
        print("🗑️ Tokens cleared")
    }
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        return accessToken != nil && refreshToken != nil
    }
    
    /// Get current access token
    var currentAccessToken: String? {
        return accessToken
    }
    
    // MARK: - Request Authorization
    
    /// Authorize a URLRequest by adding Bearer token
    func authorize(_ request: inout URLRequest) {
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    // MARK: - Token Refresh
    
    /// Refresh access token using refresh token - PRODUCTION ONLY
    func refreshTokens() async throws {
        let environment = APIEnvironment.current // Always production now
        // Prevent concurrent refresh attempts
        guard !isRefreshing else {
            // Wait briefly while another refresh completes
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            return
        }
        
        guard let refreshToken = refreshToken else {
            throw AuthError.missingRefreshToken
        }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        print("🔄 Refreshing access token...")
        
        do {
            let url = environment.v1.appendingPathComponent("auth/refresh")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json;v=1", forHTTPHeaderField: "Content-Type")
            
            // Use the shared model from APIResponseModels.swift
            let refreshBody = RefreshTokenRequest(refreshToken: refreshToken)
            request.httpBody = try JSONEncoder().encode(refreshBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            if (200..<300).contains(httpResponse.statusCode) {
                // Use the flexible TokenRefreshResponse from APIResponseModels.swift
                let refreshResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
                let newAccess = refreshResponse.actualAccessToken
                let newRefresh = refreshResponse.actualRefreshToken ?? refreshToken
                guard !newAccess.isEmpty else {
                    throw AuthError.unauthorized
                }
                
                setTokens(access: newAccess, refresh: newRefresh)
                print("✅ Access token refreshed successfully")
                
            } else {
                // Refresh failed - clear all tokens to force re-authentication
                clearTokens()
                
                if let problemDetails = try? JSONDecoder().decode(ProblemDetails.self, from: data) {
                    throw problemDetails
                } else {
                    throw AuthError.refreshFailed(httpResponse.statusCode)
                }
            }
            
        } catch {
            // On any refresh error, clear tokens
            clearTokens()
            print("❌ Token refresh failed: \(error)")
            throw error
        }
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case missingRefreshToken
    case refreshFailed(Int)
    case networkError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .missingRefreshToken:
            return "No refresh token available"
        case .refreshFailed(let code):
            return "Token refresh failed with code: \(code)"
        case .networkError:
            return "Network error during authentication"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// MARK: - Keychain Manager
private class AuthKeychainManager {
    func save(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("⚠️ Keychain save failed for key: \(key)")
        }
    }
    
    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return nil
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
