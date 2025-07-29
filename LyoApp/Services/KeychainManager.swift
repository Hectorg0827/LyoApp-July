import Foundation
import Security

// MARK: - Keychain Manager for Secure Token Storage
class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    enum KeychainKey: String {
        case authToken = "com.lyo.auth.token"
        case refreshToken = "com.lyo.auth.refresh"
        case userCredentials = "com.lyo.user.credentials"
    }
    
    func store(_ value: String, for key: KeychainKey) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain storage failed: \(status)")
        }
    }
    
    func retrieve(_ key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
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
    
    func delete(_ key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    func deleteAll() {
        KeychainKey.allCases.forEach { delete($0) }
    }
}

extension KeychainManager.KeychainKey: CaseIterable {}
