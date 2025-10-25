import Foundation
import Security
import OSLog

// MARK: - Secure Token Manager
@MainActor
final class SecureTokenManager: ObservableObject {
    static let shared = SecureTokenManager()
    
    private let logger = Logger(subsystem: "com.lyo.app", category: "SecureTokenManager")
    private let serviceName = "com.lyo.app.tokens"
    
    // Token keys
    private enum TokenKey: String, CaseIterable {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case userId = "user_id"
        case deviceId = "device_id"
        case biometricToken = "biometric_token"
    }
    
    // MARK: - Token Operations
    
    func saveAccessToken(_ token: String) {
        saveToKeychain(token, for: .accessToken)
        logger.info("🔐 Access token saved to Keychain")
    }
    
    func saveRefreshToken(_ token: String) {
        saveToKeychain(token, for: .refreshToken)
        logger.info("🔐 Refresh token saved to Keychain")
    }
    
    func saveUserId(_ userId: String) {
        saveToKeychain(userId, for: .userId)
        logger.info("🔐 User ID saved to Keychain")
    }
    
    func getAccessToken() -> String? {
        return getFromKeychain(for: .accessToken)
    }
    
    func getRefreshToken() -> String? {
        return getFromKeychain(for: .refreshToken)
    }
    
    func getUserId() -> String? {
        return getFromKeychain(for: .userId)
    }
    
    // MARK: - Batch Operations
    
    func saveAuthTokens(accessToken: String, refreshToken: String?, userId: String) {
        saveAccessToken(accessToken)
        saveUserId(userId)
        
        if let refreshToken = refreshToken {
            saveRefreshToken(refreshToken)
        }
        
        logger.info("🔐 Authentication tokens saved successfully")
    }
    
    func clearAllTokens() {
        for tokenKey in TokenKey.allCases {
            deleteFromKeychain(for: tokenKey)
        }
        
        // Also clear any legacy UserDefaults tokens
        clearLegacyTokens()
        
        logger.info("🧹 All tokens cleared from Keychain")
    }
    
    func hasValidTokens() -> Bool {
        guard let accessToken = getAccessToken(),
              let userId = getUserId() else {
            return false
        }
        
        return !accessToken.isEmpty && !userId.isEmpty
    }
    
    // MARK: - Device Security
    
    func saveDeviceId(_ deviceId: String) {
        saveToKeychain(deviceId, for: .deviceId)
    }
    
    func getDeviceId() -> String {
        if let existingId = getFromKeychain(for: .deviceId) {
            return existingId
        }
        
        // Generate new device ID
        let newDeviceId = UUID().uuidString
        saveDeviceId(newDeviceId)
        return newDeviceId
    }
    
    // MARK: - Biometric Authentication Support
    
    func saveBiometricToken(_ token: String) {
        saveToKeychainWithBiometric(token, for: .biometricToken)
        logger.info("🔐 Biometric token saved with Touch/Face ID protection")
    }
    
    func getBiometricToken() async -> String? {
        return await getFromKeychainWithBiometric(for: .biometricToken)
    }
    
    // MARK: - Private Keychain Operations
    
    private func saveToKeychain(_ value: String, for key: TokenKey) {
        let data = Data(value.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            logger.error("❌ Failed to save \(key.rawValue) to Keychain: \(status)")
        }
    }
    
    private func getFromKeychain(for key: TokenKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                logger.error("❌ Failed to retrieve \(key.rawValue) from Keychain: \(status)")
            }
            return nil
        }
        
        return string
    }
    
    private func deleteFromKeychain(for key: TokenKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("❌ Failed to delete \(key.rawValue) from Keychain: \(status)")
        }
    }
    
    // MARK: - Biometric Protected Operations
    
    private func saveToKeychainWithBiometric(_ value: String, for key: TokenKey) {
        let data = Data(value.utf8)
        
        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &accessControlError
        ) else {
            logger.error("❌ Failed to create access control for biometric authentication")
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: accessControl
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            logger.error("❌ Failed to save biometric \(key.rawValue) to Keychain: \(status)")
        }
    }
    
    private func getFromKeychainWithBiometric(for key: TokenKey) async -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseOperationPrompt as String: "Access your secure token"
        ]
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &result)
                
                guard status == errSecSuccess,
                      let data = result as? Data,
                      let string = String(data: data, encoding: .utf8) else {
                    if status != errSecItemNotFound {
                        self.logger.error("❌ Failed to retrieve biometric \(key.rawValue) from Keychain: \(status)")
                    }
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: string)
            }
        }
    }
    
    // MARK: - Migration from UserDefaults
    
    private func clearLegacyTokens() {
        // Clear old UserDefaults tokens
        UserDefaults.standard.removeObject(forKey: "lyo_auth_token")
        UserDefaults.standard.removeObject(forKey: "lyo_refresh_token")
        UserDefaults.standard.removeObject(forKey: "lyo_user_id")
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        
        logger.info("🧹 Legacy UserDefaults tokens cleared")
    }
    
    func migrateLegacyTokens() {
        // Migrate from UserDefaults to Keychain if tokens exist
        if let accessToken = UserDefaults.standard.string(forKey: "lyo_auth_token") {
            saveAccessToken(accessToken)
            logger.info("📦 Migrated access token from UserDefaults to Keychain")
        }
        
        if let refreshToken = UserDefaults.standard.string(forKey: "lyo_refresh_token") {
            saveRefreshToken(refreshToken)
            logger.info("📦 Migrated refresh token from UserDefaults to Keychain")
        }
        
        if let userId = UserDefaults.standard.string(forKey: "lyo_user_id") {
            saveUserId(userId)
            logger.info("📦 Migrated user ID from UserDefaults to Keychain")
        }
        
        // Clear legacy tokens after migration
        clearLegacyTokens()
    }
    
    // MARK: - Token Validation
    
    func validateTokenFormat(_ token: String) -> Bool {
        // Basic JWT format validation (header.payload.signature)
        let components = token.components(separatedBy: ".")
        return components.count == 3 && !token.isEmpty
    }
    
    func isTokenExpired(_ token: String) -> Bool {
        // Basic JWT expiration check
        guard validateTokenFormat(token) else { return true }
        
        let components = token.components(separatedBy: ".")
        guard components.count >= 2 else { return true }
        
        // Decode payload (base64 URL safe)
        let payload = components[1]
        let paddedPayload = payload.padding(toLength: ((payload.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
        
        guard let payloadData = Data(base64Encoded: paddedPayload.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return true
        }
        
        return Date().timeIntervalSince1970 >= exp
    }
    
    // MARK: - Debug Information
    
    func getTokenStatus() -> [String: Any] {
        return [
            "hasAccessToken": getAccessToken() != nil,
            "hasRefreshToken": getRefreshToken() != nil,
            "hasUserId": getUserId() != nil,
            "deviceId": getDeviceId(),
            "hasValidTokens": hasValidTokens(),
            "accessTokenValid": {
                guard let token = getAccessToken() else { return false }
                return validateTokenFormat(token) && !isTokenExpired(token)
            }()
        ]
    }
    
    private init() {
        // Perform migration on initialization
        migrateLegacyTokens()
        logger.info("🔐 SecureTokenManager initialized")
    }
}