import Foundation
import Combine
import SwiftUI

// MARK: - Authentication Service

@MainActor
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let keychain = KeychainService.shared
    private let apiService = RealAPIService.shared
    
    private init() {
        loadStoredAuth()
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: AuthResponse = try await apiService.authenticate(email: email, password: password)
            
            await handleAuthSuccess(response)
            return true
            
        } catch {
            await handleAuthError(error)
            return false
        }
    }
    
    func signUp(email: String, password: String, fullName: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: AuthResponse = try await apiService.register(email: email, password: password, username: email, fullName: fullName)
            
            await handleAuthSuccess(response)
            return true
            
        } catch {
            await handleAuthError(error)
            return false
        }
    }
    
    func signOut() async {
        // Clear server session
        do {
            // let _: EmptyResponse = try await apiService.performRequest(
            //     endpoint: "/auth/signout",
            //     method: "POST",
            //     body: Optional<String>.none,
            //     responseType: EmptyResponse.self
            // )
            print("🚪 Would sign out from server")
        } catch {
            print("⚠️ Error signing out on server: \(error)")
        }
        
        // Clear local data
        await clearAuthData()
    }
    
    func refreshToken() async -> Bool {
        guard let refreshToken = keychain.getValue(for: "refresh_token") else {
            await signOut()
            return false
        }
        
        do {
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            // let response: AuthResponse = try await apiService.performRequest(
            //     endpoint: "/auth/refresh",
            //     method: "POST",
            //     body: request,
            //     responseType: AuthResponse.self
            // )
            print("🔄 Would refresh token")
            return false // Temporarily return false
            
            // await handleAuthSuccess(response)
            // return true
            
        } catch {
            await signOut()
            return false
        }
    }
    
    func resetPassword(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = ResetPasswordRequest(email: email)
            // let _: EmptyResponse = try await apiService.performRequest(
            //     endpoint: "/auth/reset-password",
            //     method: "POST",
            //     body: request,
            //     responseType: EmptyResponse.self
            // )
            print("📧 Would send reset password email to \(email)")
            
            isLoading = false
            return true
            
        } catch {
            await handleAuthError(error)
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleAuthSuccess(_ response: AuthResponse) async {
        self.authToken = response.accessToken
        self.currentUser = response.user
        self.isAuthenticated = true
        self.isLoading = false
        
        // Store in keychain
        keychain.setValue(response.accessToken, for: "access_token")
        keychain.setValue(response.refreshToken, for: "refresh_token")
        
        // Store user data
        if let userData = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(userData, forKey: "current_user")
        }
        
        print("✅ Authentication successful for user: \(response.user.email)")
    }
    
    private func handleAuthError(_ error: Error) async {
        self.isLoading = false
        self.errorMessage = error.localizedDescription
        print("❌ Authentication error: \(error)")
    }
    
    private func clearAuthData() async {
        self.authToken = nil
        self.currentUser = nil
        self.isAuthenticated = false
        self.isLoading = false
        self.errorMessage = nil
        
        // Clear keychain
        keychain.removeValue(for: "access_token")
        keychain.removeValue(for: "refresh_token")
        
        // Clear user defaults
        UserDefaults.standard.removeObject(forKey: "current_user")
        
        print("🔐 Authentication data cleared")
    }
    
    private func loadStoredAuth() {
        guard let token = keychain.getValue(for: "access_token"),
              let userData = UserDefaults.standard.data(forKey: "current_user"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return
        }
        
        self.authToken = token
        self.currentUser = user
        self.isAuthenticated = true
        
        // Validate token in background
        Task {
            _ = await refreshToken()
        }
    }
}

// MARK: - Keychain Service

class KeychainService {
    static let shared = KeychainService()
    private init() {}
    
    func setValue(_ value: String, for key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("⚠️ Keychain save failed for key: \(key)")
        }
    }
    
    func getValue(for key: String) -> String? {
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
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func removeValue(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Auth Data Models

struct SignInRequest: Codable {
    let email: String
    let password: String
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let fullName: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct ResetPasswordRequest: Codable {
    let email: String
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct EmptyResponse: Codable {}

// MARK: - Auth Extensions

extension User {
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.dropFirst().first?.first?.uppercased() ?? ""
        return firstInitial + lastInitial
    }
    
    var isVerified: Bool {
        // Check if user has verified email
        return true // Placeholder - implement based on your user model
    }
}

// MARK: - Authentication Views Helper

extension View {
    func requiresAuthentication() -> some View {
        self.modifier(AuthenticationModifier())
    }
}

struct AuthenticationModifier: ViewModifier {
    @StateObject private var authService = AuthenticationService.shared
    
    func body(content: Content) -> some View {
        Group {
            if authService.isAuthenticated {
                content
            } else {
                AuthenticationView()
            }
        }
    }
}
