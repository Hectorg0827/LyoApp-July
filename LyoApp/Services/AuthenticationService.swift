import Foundation
import Combine
import SwiftUI

// MARK: - Auth Data Models
// Using the models defined in the global namespace

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
    private let keychain = KeychainManager.shared
    private let apiService = RealAPIService.shared
    
    private init() {
        loadStoredAuth()
    }
    
    // MARK: - Private Helper Methods
    
    private func handleAuthSuccess(_ response: AuthResponse) async {
        self.authToken = response.accessToken
        self.currentUser = response.user
        self.isAuthenticated = true
        self.isLoading = false
        self.errorMessage = nil
        
        // Store tokens
        keychain.store(response.accessToken, for: .authToken)
        keychain.store(response.refreshToken, for: .refreshToken)
        
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
        keychain.delete(.authToken)
        keychain.delete(.refreshToken)
        
        // Clear user defaults
        UserDefaults.standard.removeObject(forKey: "current_user")
        
        print("🔐 Authentication data cleared")
    }
    
    private func loadStoredAuth() {
        guard let token = keychain.retrieve(.authToken),
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
            let _: EmptyResponse = try await apiService.performRequest(
                endpoint: "/auth/signout",
                method: "POST",
                body: Optional<String>.none,
                responseType: EmptyResponse.self
            )
        } catch {
            print("Error signing out: \(error)")
        }
        
        // Clear local data
        await clearAuthData()
    }
    
    func refreshToken() async -> Bool {
        guard let refreshToken = keychain.retrieve(.refreshToken) else {
            await signOut()
            return false
        }
        
        do {
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            let response: AuthResponse = try await apiService.performRequest(
                endpoint: "/auth/refresh",
                method: "POST",
                body: request,
                responseType: AuthResponse.self
            )
            await handleAuthSuccess(response)
            return true
        } catch {
            print("Error refreshing token: \(error)")
            // If refresh fails, sign out the user
            await signOut()
            return false
        }
    }
    
    func resetPassword(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = ResetPasswordRequest(email: email)
            let _: EmptyResponse = try await apiService.performRequest(
                endpoint: "/auth/reset-password",
                method: "POST",
                body: request,
                responseType: EmptyResponse.self
            )
            isLoading = false
            return true
        } catch {
            await handleAuthError(error)
            return false
        }
    }
}

// MARK: - Import KeychainManager
// KeychainService implementation replaced with KeychainManager

// Use RealAPIService models instead of duplicating them here

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
