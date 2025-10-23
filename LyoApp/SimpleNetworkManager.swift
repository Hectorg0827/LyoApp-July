import Foundation
import Combine

// MARK: - Simple Network Manager for Backend Integration
@MainActor 
class SimpleNetworkManager: ObservableObject {
    static let shared = SimpleNetworkManager()
    
    #if DEBUG
    private let baseURL = "http://localhost:8000"
    #else
    private let baseURL = "https://lyo-backend-830162750094.us-central1.run.app"
    #endif
    private let session = URLSession.shared
    
    @Published var isAuthenticated = false
    @Published var currentUser: APIUser?
    @Published var authToken: String?
    
    private init() {
        loadAuthToken()
    }
    
    private func loadAuthToken() {
        authToken = UserDefaults.standard.string(forKey: "auth_token")
        isAuthenticated = authToken != nil
    }
    
    private func saveAuthToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "auth_token")
        authToken = token
        isAuthenticated = true
    }
    
    private func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
        authToken = nil
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Authentication Methods
    func login(email: String, password: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/api/v1/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginData = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "LoginError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Login failed"])
        }
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        await MainActor.run {
            saveAuthToken(loginResponse.token)
            currentUser = loginResponse.user
        }
        
        return loginResponse
    }
    
    func register(name: String, email: String, password: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/api/v1/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let registerData = ["name": name, "email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: registerData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "RegisterError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Registration failed"])
        }
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        await MainActor.run {
            saveAuthToken(loginResponse.token)
            currentUser = loginResponse.user
        }
        
        return loginResponse
    }
    
    func logout() {
        clearAuthToken()
    }
    
    func healthCheck() async throws -> HealthResponse {
        let url = URL(string: "\(baseURL)/api/v1/health")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }
}
