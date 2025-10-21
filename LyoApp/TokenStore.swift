import Foundation

/// Secure token storage manager
final class TokenStore {
    static let shared = TokenStore()
    
    private let accessTokenKey = "lyo_access_token"
    private let refreshTokenKey = "lyo_refresh_token"
    private let userIdKey = "lyo_user_id"
    
    private init() {}
    
    // MARK: - Token Management
    
    func save(accessToken: String, refreshToken: String, userId: String? = nil) {
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        
        if let userId = userId {
            UserDefaults.standard.set(userId, forKey: userIdKey)
        }
        
        // Notify APIClient of new token
        updateAPIClientToken(accessToken)
    }
    
    func loadTokens() -> (accessToken: String, refreshToken: String, userId: String?)? {
        guard let accessToken = UserDefaults.standard.string(forKey: accessTokenKey),
              let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) else {
            return nil
        }
        
        let userId = UserDefaults.standard.string(forKey: userIdKey)
        return (accessToken, refreshToken, userId)
    }
    
    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: accessTokenKey)
    }
    
    func clearAllTokens() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        
        // Clear APIClient token
        updateAPIClientToken(nil)
    }
    
    func isAuthenticated() -> Bool {
        return getAccessToken() != nil
    }
    
    // MARK: - Private Helpers
    
    private func updateAPIClientToken(_ token: String?) {
        // Update the APIClient's auth shim
        if let token = token {
            UserDefaults.standard.set(token, forKey: "lyo_auth_token")
        } else {
            UserDefaults.standard.removeObject(forKey: "lyo_auth_token")
        }
    }
}
