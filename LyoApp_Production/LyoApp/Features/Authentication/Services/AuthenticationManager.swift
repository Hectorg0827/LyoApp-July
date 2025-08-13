import Foundation
import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let networkManager = NetworkManager.shared // Made public for access from views
    private let keychain = KeychainManager.shared
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        if let token = keychain.getToken() {
            networkManager.setAuthToken(token)
            isAuthenticated = true
            Task {
                await fetchCurrentUser()
            }
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        print("🔐 Attempting login for: \(email)")
        
        do {
            let loginRequest = LoginRequest(email: email, password: password)
            let requestData = try JSONEncoder().encode(loginRequest)
            
            print("📤 Sending login request to: \(BackendConfig.fullBaseURL + BackendConfig.Endpoints.login)")
            
            let response: LoginResponse = try await networkManager.post(
                endpoint: BackendConfig.Endpoints.login,
                body: requestData,
                responseType: LoginResponse.self
            )
            
            print("✅ Login successful! Token: \(response.token.prefix(10))...")
            
            // Store token securely
            keychain.setToken(response.token)
            networkManager.setAuthToken(response.token)
            
            // Update state
            currentUser = response.user
            isAuthenticated = true
            
            print("👤 User authenticated: \(response.user.name)")
            
        } catch {
            let errorMsg = "Login failed: \(error.localizedDescription)"
            print("❌ \(errorMsg)")
            errorMessage = errorMsg
        }
        
        isLoading = false
    }
    
    func register(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let registerRequest = RegisterRequest(
                email: email,
                password: password,
                fullName: fullName
            )
            let requestData = try JSONEncoder().encode(registerRequest)
            
            let response: RegisterResponse = try await networkManager.post(
                endpoint: BackendConfig.Endpoints.register,
                body: requestData,
                responseType: RegisterResponse.self
            )
            
            // Store token securely
            keychain.setToken(response.token)
            networkManager.setAuthToken(response.token)
            
            // Update state
            currentUser = response.user
            isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() async {
        do {
            let _: LogoutResponse = try await networkManager.post(
                endpoint: BackendConfig.Endpoints.logout,
                body: Data(),
                responseType: LogoutResponse.self
            )
        } catch {
            print("Logout error: \(error)")
        }
        
        // Clear local data
        keychain.clearToken()
        networkManager.clearAuthToken()
        currentUser = nil
        isAuthenticated = false
    }
    
    private func fetchCurrentUser() async {
        do {
            let user: User = try await networkManager.get(
                endpoint: BackendConfig.Endpoints.userProfile,
                responseType: User.self
            )
            currentUser = user
        } catch {
            print("Failed to fetch current user: \(error)")
        }
    }
}

// MARK: - Request/Response Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let user: User
    let expiresIn: Int?
    
    enum CodingKeys: String, CodingKey {
        case token, user
        case expiresIn = "expires_in"
    }
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let fullName: String
    
    enum CodingKeys: String, CodingKey {
        case email, password
        case fullName = "fullName"
    }
}

struct RegisterResponse: Codable {
    let success: Bool?
    let token: String
    let user: User
    let message: String?
}

struct LogoutResponse: Codable {
    let message: String
}
