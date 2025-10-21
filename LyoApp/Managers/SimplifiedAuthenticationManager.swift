import Foundation
import LocalAuthentication
import SwiftUI
import OSLog

// MARK: - Authentication Error
enum AuthenticationError: LocalizedError {
    case invalidInput
    case invalidEmail
    case invalidCredentials
    case passwordTooShort
    case userNotFound
    case registrationFailed
    case emailAlreadyExists(String)
    case biometricNotAvailable
    case biometricFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please fill in all required fields"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidCredentials:
            return "Invalid username or password. Please check and try again."
        case .passwordTooShort:
            return "Password must be at least 6 characters long"
        case .userNotFound:
            return "No account found with this email. Please sign up first."
        case .registrationFailed:
            return "Failed to create account. Please try again."
        case .emailAlreadyExists(let email):
            return "Email '\(email)' is already registered. Please login instead."
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricFailed:
            return "Biometric authentication failed"
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}

// MARK: - Simplified Authentication Manager for Backend Integration
@MainActor
public final class SimplifiedAuthenticationManager: ObservableObject {
    static let shared = SimplifiedAuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    private let keychain = AuthKeychainHelper()
    private let logger = Logger(subsystem: "com.lyo.app", category: "AuthManager")
    
    private init() {
        loadAuthStateSafely()
    }
    
    // MARK: - Authentication State
    private func loadAuthStateSafely() {
        // If tokens exist, AppState will restore the session and currentUser later
        if TokenStore.shared.isAuthenticated() {
            isAuthenticated = true
        } else if let user = loadUser() {
            // Legacy local persistence fallback (should not happen in production)
            currentUser = user
            isAuthenticated = true
        }
    }
    
    // MARK: - Registration (Local until backend auth is ready)
    func register(
        username: String,
        email: String,
        password: String,
        fullName: String
    ) async -> Result<User, AuthenticationError> {
        
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            let error = AuthenticationError.invalidInput
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        guard isValidEmail(email) else {
            let error = AuthenticationError.invalidEmail
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        guard password.count >= 6 else {
            let error = AuthenticationError.passwordTooShort
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Check if user already exists locally
        let existingUsers = loadAllUsers()
        print("📋 Existing users count: \(existingUsers.count)")
        for user in existingUsers {
            print("  - \(user.email) (\(user.username))")
        }
        
        if existingUsers.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            isLoading = false
            let error = AuthenticationError.emailAlreadyExists(email)
            errorMessage = error.errorDescription
            logger.error("❌ Registration failed: Email already exists - \(email)")
            return .failure(error)
        }
        
        // Create new user locally
        let newUser = User(
            id: UUID(),
            username: username,
            email: email,
            fullName: fullName,
            bio: "New user on LyoApp"
        )
        
        // Store user and credentials locally
        saveUser(newUser, password: password)
        
        // Generate mock tokens
        let mockAccessToken = "local_token_\(UUID().uuidString)"
        AppState.shared.setAuthTokens(
            accessToken: mockAccessToken,
            refreshToken: mockAccessToken,
            userId: newUser.id.uuidString
        )
        
        currentUser = newUser
        isAuthenticated = true
        
        // Persist user for session restoration
        if let userData = try? JSONEncoder().encode(newUser) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        keychain.save("auth_token_marker", service: "LyoApp", account: "authToken")
        
        isLoading = false
        logger.info("✅ Local registration successful: \(newUser.username)")
        return .success(newUser)
    }
    
    // MARK: - Login (Local until backend auth is ready)
    func login(username: String, password: String) async -> Result<User, AuthenticationError> {
        isLoading = true
        errorMessage = nil
        
        guard !username.isEmpty, !password.isEmpty else {
            isLoading = false
            let error = AuthenticationError.invalidCredentials
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Check local storage for user
        let allUsers = loadAllUsers()
        
        // Find user by email or username
        guard let user = allUsers.first(where: { 
            $0.email.lowercased() == username.lowercased() || 
            $0.username.lowercased() == username.lowercased() 
        }) else {
            isLoading = false
            let error = AuthenticationError.invalidCredentials
            errorMessage = "User not found. Please register first."
            logger.error("❌ Login failed: User not found")
            return .failure(error)
        }
        
        // Verify password
        let storedPassword = loadPassword(for: user.id.uuidString)
        guard storedPassword == password else {
            isLoading = false
            let error = AuthenticationError.invalidCredentials
            errorMessage = "Invalid password"
            logger.error("❌ Login failed: Invalid password")
            return .failure(error)
        }
        
        // Generate mock tokens
        let mockAccessToken = "local_token_\(UUID().uuidString)"
        AppState.shared.setAuthTokens(
            accessToken: mockAccessToken,
            refreshToken: mockAccessToken,
            userId: user.id.uuidString
        )
        
        currentUser = user
        isAuthenticated = true
        
        // Persist user for session restoration
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        keychain.save("auth_token_marker", service: "LyoApp", account: "authToken")
        
        isLoading = false
        logger.info("✅ Local login successful: \(user.username)")
        return .success(user)
    }
    
    // MARK: - Logout
    func logout() async {
        isLoading = true
        
        // Clear stored credentials
        keychain.delete(service: "LyoApp", account: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        TokenStore.shared.clearAllTokens()
        APIClient.shared.clearAuthTokens()
        
        // Clear local state
        currentUser = nil
        isAuthenticated = false
        isLoading = false
        
        // Disconnect any live socket
        LyoWebSocketService.shared.disconnect()
        
        logger.info("✅ User logged out successfully")
    }
    
    // MARK: - Helper Methods
    private func loadUser() -> User? {
        guard let userData = UserDefaults.standard.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return nil
        }
        return user
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Local Storage Helpers
    
    /// Save user to local storage with password
    private func saveUser(_ user: User, password: String) {
        var users = loadAllUsers()
        
        // Remove existing user with same ID if any
        users.removeAll { $0.id == user.id }
        
        // Add new user
        users.append(user)
        
        // Save users array
        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: "localUsers")
        }
        
        // Save password separately (in production, this should be hashed)
        UserDefaults.standard.set(password, forKey: "password_\(user.id.uuidString)")
        
        logger.info("💾 Saved user locally: \(user.email)")
    }
    
    /// Load all users from local storage
    private func loadAllUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: "localUsers"),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }
    
    /// Load password for a specific user
    private func loadPassword(for userId: String) -> String? {
        return UserDefaults.standard.string(forKey: "password_\(userId)")
    }
    
    /// Check if email already exists in local storage
    private func userExists(email: String) -> Bool {
        let users = loadAllUsers()
        return users.contains { $0.email.lowercased() == email.lowercased() }
    }
    
    // MARK: - Apple Sign-In Support
    
    /// Store user from Apple Sign-In
    func storeAppleUser(_ user: User) async {
        // Save user without password (Apple Sign-In doesn't use passwords)
        var users = loadAllUsers()
        users.removeAll { $0.id == user.id }
        users.append(user)
        
        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: "localUsers")
        }
        
        // Mark as Apple Sign-In user
        UserDefaults.standard.set(true, forKey: "appleUser_\(user.id.uuidString)")
        
        // Generate mock tokens
        let mockAccessToken = "apple_token_\(UUID().uuidString)"
        AppState.shared.setAuthTokens(
            accessToken: mockAccessToken,
            refreshToken: mockAccessToken,
            userId: user.id.uuidString
        )
        
        currentUser = user
        isAuthenticated = true
        
        // Persist user for session restoration
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        keychain.save("auth_token_marker", service: "LyoApp", account: "authToken")
        
        logger.info("✅ Apple Sign-In user stored: \(user.email)")
    }
}

// MARK: - AuthKeychainHelper
final class AuthKeychainHelper {
    func save(_ string: String, service: String, account: String) {
        let data = string.data(using: .utf8)!
        save(data, service: service, account: account)
    }
    
    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func load(service: String, account: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
    }
}
