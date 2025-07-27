import Foundation
import Combine

// Local HTTPMethod enum for LyoAPIService
enum LyoHTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// Empty response for endpoints that don't return data
struct EmptyResponse: Codable {}

/// Enhanced API service for Lyo AI Learn Buddy backend integration
@MainActor
class LyoAPIService: ObservableObject {
    static let shared = LyoAPIService()
    
    // MARK: - Configuration
    private let baseURL = "http://localhost:8000"
    private var session = URLSession.shared
    
    // MARK: - Authentication Storage
    private var authToken: String? {
        get {
            UserDefaults.standard.string(forKey: "lyo_auth_token")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lyo_auth_token")
        }
    }
    
    private var currentUserId: Int? {
        get {
            let id = UserDefaults.standard.integer(forKey: "lyo_current_user_id")
            return id > 0 ? id : nil
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "lyo_current_user_id")
            } else {
                UserDefaults.standard.removeObject(forKey: "lyo_current_user_id")
            }
        }
    }
    
    // MARK: - Published State
    @Published var isConnected = false
    @Published var lastError: APIError?
    @Published var isLoading = false
    
    // MARK: - Authentication
    @Published var isAuthenticated = false
    @Published var currentUser: APIUser?
    
    private init() {
        // Initialize without APIClient dependency for now
        // Will implement backend integration methods directly
        checkConnection()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Connection Management
    
    func checkConnection() {
        Task {
            // Direct health check implementation
            do {
                let _ = try await performHealthCheck()
                await MainActor.run {
                    self.isConnected = true
                }
            } catch {
                await MainActor.run {
                    self.isConnected = false
                }
            }
            
            // Also check legacy endpoints
            await checkLegacyConnection()
        }
    }
    
    private func performHealthCheck() async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode, "Health check failed")
        }
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    @MainActor
    private func checkLegacyConnection() async {
        let healthEndpoints = ["/health", "/api/health", "/api/v1/health"]
        tryNextHealthEndpoint(endpoints: healthEndpoints, index: 0)
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await performLogin(email: email, password: password)
            currentUser = response.user
            isAuthenticated = true
            lastError = nil
            
            // Store additional auth info for legacy endpoints
            authToken = response.token
            if let userId = Int(response.user.id) {
                currentUserId = userId
            }
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    private func performLogin(email: String, password: String) async throws -> LoginResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/login") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginData = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode, "Login failed")
        }
        
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
    
    func logout() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await performLogout()
        } catch {
            print("⚠️ Logout error: \(error)")
        }
        
        currentUser = nil
        isAuthenticated = false
        lastError = nil
        authToken = nil
        currentUserId = nil
    }
    
    private func performLogout() async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/logout") else {
            return // Not critical if logout endpoint fails
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        // Don't throw error if logout fails - always clear local state
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            print("⚠️ Backend logout failed with status: \(httpResponse.statusCode)")
        }
    }
    
    private func tryNextHealthEndpoint(endpoints: [String], index: Int) {
        guard index < endpoints.count else {
            // All endpoints failed
            DispatchQueue.main.async {
                self.isConnected = false
                self.lastError = .networkError(NSError(
                    domain: "ConnectionError", 
                    code: 0, 
                    userInfo: [NSLocalizedDescriptionKey: "Backend server not reachable at \(self.baseURL). Please start your backend server."]
                ))
                print("❌ Backend server not running at \(self.baseURL)")
                print("🔧 To fix: Start your backend server on port 8000")
            }
            return
        }
        
        let endpoint = endpoints[index]
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            tryNextHealthEndpoint(endpoints: endpoints, index: index + 1)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0
        
        session.dataTask(with: request) { [weak self] data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self?.isConnected = true
                    self?.lastError = nil
                    print("✅ Connected to backend at: \(url.absoluteString)")
                }
            } else {
                // Try next endpoint on main actor
                Task { @MainActor in
                    self?.tryNextHealthEndpoint(endpoints: endpoints, index: index + 1)
                }
            }
        }.resume()
    }
    
    // MARK: - Token Management
    func setAuthToken(_ token: String, userId: Int) {
        authToken = token
        currentUserId = userId
    }
    
    func clearAuthToken() {
        authToken = nil
        currentUserId = nil
    }
    
    func hasAuthToken() -> Bool {
        return authToken != nil
    }
}

// MARK: - Response Models (simple versions for core functionality)
struct LoginResponse: Codable {
    let token: String
    let user: APIUser
}

struct APIUser: Codable {
    let id: String
    let name: String
    let email: String
    let role: String
}
