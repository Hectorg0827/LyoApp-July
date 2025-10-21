import Foundation
import os.log

// MARK: - Token Manager with Single-Flight Refresh
@MainActor
class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LyoApp", category: "TokenManager")
    
    @Published var isAuthenticated: Bool = false
    @Published var accessToken: String?
    @Published var refreshToken: String?
    
    private var tokenExpiryDate: Date?
    private var refreshTask: Task<String, Error>?
    
    // Correlation ID for debugging
    private func generateCorrelationId() -> String {
        return UUID().uuidString.prefix(8).lowercased()
    }
    
    private init() {
        loadStoredTokens()
    }
    
    // MARK: - Token Storage
    private func loadStoredTokens() {
        let correlationId = generateCorrelationId()
        logger.info("[\(correlationId)] Loading stored tokens")
        
        accessToken = KeychainManager.getToken(for: "access_token")
        refreshToken = KeychainManager.getToken(for: "refresh_token")
        
        if let expiryString = UserDefaults.standard.string(forKey: "token_expiry"),
           let expiryDate = ISO8601DateFormatter().date(from: expiryString) {
            tokenExpiryDate = expiryDate
        }
        
        isAuthenticated = accessToken != nil && !isTokenExpired()
        
        if isAuthenticated {
            logger.info("[\(correlationId)] ✅ Valid tokens found")
        } else {
            logger.info("[\(correlationId)] ⚠️ No valid tokens found")
        }
    }
    
    private func storeTokens(accessToken: String, refreshToken: String, expiryDate: Date) {
        let correlationId = generateCorrelationId()
        logger.info("[\(correlationId)] Storing new tokens")
        
        KeychainManager.storeToken(accessToken, for: "access_token")
        KeychainManager.storeToken(refreshToken, for: "refresh_token")
        
        let expiryString = ISO8601DateFormatter().string(from: expiryDate)
        UserDefaults.standard.set(expiryString, forKey: "token_expiry")
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiryDate = expiryDate
        self.isAuthenticated = true
        
        logger.info("[\(correlationId)] ✅ Tokens stored successfully")
    }
    
    // MARK: - Token Validation
    private func isTokenExpired() -> Bool {
        guard let expiryDate = tokenExpiryDate else { return true }
        // Consider token expired 5 minutes before actual expiry for safety
        return Date().addingTimeInterval(300) >= expiryDate
    }
    
    func getValidAccessToken() async throws -> String {
        let correlationId = generateCorrelationId()
        logger.info("[\(correlationId)] Getting valid access token")
        
        // If we have a valid token, return it
        if let token = accessToken, !isTokenExpired() {
            logger.info("[\(correlationId)] ✅ Using existing valid token")
            return token
        }
        
        // If token is expired or missing, refresh it
        return try await refreshAccessToken(correlationId: correlationId)
    }
    
    // MARK: - Single-Flight Token Refresh
    private func refreshAccessToken(correlationId: String) async throws -> String {
        logger.info("[\(correlationId)] Starting token refresh")
        
        // If there's already a refresh task in progress, wait for it
        if let existingTask = refreshTask {
            logger.info("[\(correlationId)] ⏳ Waiting for existing refresh task")
            do {
                let token = try await existingTask.value
                logger.info("[\(correlationId)] ✅ Got token from existing refresh task")
                return token
            } catch {
                // If existing task failed, we'll create a new one below
                logger.warning("[\(correlationId)] ⚠️ Existing refresh task failed: \(error)")
                refreshTask = nil
            }
        }
        
        // Create new refresh task
        let task = Task<String, Error> {
            do {
                logger.info("[\(correlationId)] 🔄 Executing token refresh")
                
                guard let currentRefreshToken = refreshToken else {
                    logger.error("[\(correlationId)] ❌ No refresh token available")
                    await clearTokens()
                    throw TokenError.noRefreshToken
                }
                
                // Call refresh endpoint
                let response = try await APIClient.shared.refreshToken(refreshToken: currentRefreshToken)
                
                // Calculate expiry date (assuming token is valid for 1 hour)
                let expiryDate = Date().addingTimeInterval(3600)
                
                // Store new tokens
                storeTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken ?? currentRefreshToken,
                    expiryDate: expiryDate
                )
                
                logger.info("[\(correlationId)] ✅ Token refresh successful")
                return response.accessToken
                
            } catch {
                logger.error("[\(correlationId)] ❌ Token refresh failed: \(error)")
                
                // If refresh failed, clear tokens and require re-authentication
                if case APIClientError.unauthorized = error {
                    await clearTokens()
                }
                
                throw error
            }
        }
        
        refreshTask = task
        
        do {
            let token = try await task.value
            refreshTask = nil
            return token
        } catch {
            refreshTask = nil
            throw error
        }
    }
    
    // MARK: - Authentication Management
    func setTokens(accessToken: String, refreshToken: String, expiresIn: TimeInterval = 3600) {
        let correlationId = generateCorrelationId()
        logger.info("[\(correlationId)] Setting new authentication tokens")
        
        let expiryDate = Date().addingTimeInterval(expiresIn)
        storeTokens(accessToken: accessToken, refreshToken: refreshToken, expiryDate: expiryDate)
    }
    
    func clearTokens() {
        let correlationId = generateCorrelationId()
        logger.info("[\(correlationId)] Clearing authentication tokens")
        
        KeychainManager.deleteToken(for: "access_token")
        KeychainManager.deleteToken(for: "refresh_token")
        UserDefaults.standard.removeObject(forKey: "token_expiry")
        
        accessToken = nil
        refreshToken = nil
        tokenExpiryDate = nil
        isAuthenticated = false
        
        // Cancel any pending refresh task
        refreshTask?.cancel()
        refreshTask = nil
        
        logger.info("[\(correlationId)] ✅ Tokens cleared")
    }
    
    func logout() async {
        let correlationId = generateCorrelationId()
        logger.info("[\(correlationId)] Logging out user")
        
        // Attempt to notify backend of logout
        if let token = accessToken {
            do {
                try await APIClient.shared.logout(token: token)
                logger.info("[\(correlationId)] ✅ Backend logout successful")
            } catch {
                logger.warning("[\(correlationId)] ⚠️ Backend logout failed: \(error)")
                // Continue with local logout even if backend fails
            }
        }
        
        clearTokens()
    }
}

// MARK: - Token Errors
enum TokenError: LocalizedError {
    case noRefreshToken
    case refreshFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noRefreshToken:
            return "No refresh token available. Please log in again."
        case .refreshFailed(let error):
            return "Token refresh failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Keychain Manager Helper
class KeychainManager {
    static func storeToken(_ token: String, for key: String) {
        guard let data = token.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func getToken(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    static func deleteToken(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Token Refresh Response
struct TokenRefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}