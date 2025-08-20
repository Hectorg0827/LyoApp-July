import Foundation
import os.log

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func get<T: Codable>(endpoint: String) async throws -> T
    func post<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T
    func put<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T
    func delete(endpoint: String) async throws
    
    // Authentication methods
    func login(email: String, password: String) async throws -> LoginResponse
    func logout() async throws
    func refreshToken() async throws -> LoginResponse
    
    // Health check
    func healthCheck() async throws -> HealthResponse
}

// MARK: - Real API Client
class APIClient: APIClientProtocol, ObservableObject {
    static let shared = APIClient()
    
    private let session: URLSession
    private let logger = Logger(subsystem: "com.lyo.app", category: "APIClient")
    
    @Published var isConnected = false
    @Published var lastConnectionCheck = Date()
    
    // Token storage (you might want to use Keychain for production)
    private var authToken: String? {
        get {
            UserDefaults.standard.string(forKey: "auth_token")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "auth_token")
        }
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        config.timeoutIntervalForResource = APIConfig.uploadTimeout
        self.session = URLSession(configuration: config)
        
        // Check connection on initialization
        Task {
            await checkBackendConnection()
        }
    }
    
    // MARK: - Connection Management
    @MainActor
    func checkBackendConnection() async {
        do {
            let _: HealthResponse = try await healthCheck()
            isConnected = true
            lastConnectionCheck = Date()
            logger.info("✅ Backend connection established")
        } catch {
            isConnected = false
            logger.error("❌ Backend connection failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Generic Request Method
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Codable? = nil
    ) async throws -> T {
        guard let url = URL(string: APIConfig.baseURL + "/" + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add request body
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.decodingError(error)
            }
        }
        
        if DevelopmentConfig.enableDebugLogging {
            logger.info("🌐 \(method.rawValue) \(url.absoluteString)")
            if let bodyData = request.httpBody,
               let bodyString = String(data: bodyData, encoding: .utf8) {
                logger.info("📦 Request body: \(bodyString)")
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
            }
            
            if DevelopmentConfig.enableDebugLogging {
                logger.info("📥 Response: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.info("📦 Response body: \(responseString)")
                }
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                // Clear invalid token
                authToken = nil
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 400...499:
                let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.serverError(httpResponse.statusCode, errorMessage?.detail)
            case 500...599:
                let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.serverError(httpResponse.statusCode, errorMessage?.detail)
            default:
                throw APIError.serverError(httpResponse.statusCode, nil)
            }
            
            // Decode response
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                return result
            } catch {
                logger.error("❌ Decoding error: \(error)")
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            logger.error("❌ Network error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Protocol Methods
    func get<T: Codable>(endpoint: String) async throws -> T {
        return try await request(endpoint: endpoint, method: HTTPMethod.GET)
    }
    
    func post<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T {
        return try await request(endpoint: endpoint, method: HTTPMethod.POST, body: body)
    }
    
    func put<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T {
        return try await request(endpoint: endpoint, method: HTTPMethod.PUT, body: body)
    }
    
    func delete(endpoint: String) async throws {
        let _: EmptyResponse = try await request(endpoint: endpoint, method: HTTPMethod.DELETE)
    }
    
    // MARK: - Token Management
    func setAuthToken(_ token: String) {
        authToken = token
        logger.info("🔐 Auth token set")
    }
    
    func clearAuthToken() {
        authToken = nil
        logger.info("🔓 Auth token cleared")
    }
    
    func hasAuthToken() -> Bool {
        return authToken != nil
    }
    
    // MARK: - Authentication Methods
    func login(email: String, password: String) async throws -> LoginResponse {
        let loginRequest = LoginRequest(email: email, password: password)
        let response: LoginResponse = try await post(endpoint: "auth/login", body: loginRequest)
        
        // Store the token
        setAuthToken(response.token)
        logger.info("🔐 User logged in successfully")
        
        return response
    }
    
    func logout() async throws {
        // Call backend logout endpoint if available
        do {
            let _: EmptyResponse = try await post(endpoint: "auth/logout", body: EmptyRequest())
        } catch {
            // Continue with local logout even if backend call fails
            logger.warning("⚠️ Backend logout failed, continuing with local logout")
        }
        
        // Clear local token
        clearAuthToken()
        logger.info("🔓 User logged out")
    }
    
    func refreshToken() async throws -> LoginResponse {
        guard hasAuthToken() else {
            throw APIError.unauthorized
        }
        
    let response: LoginResponse = try await post(endpoint: "auth/refresh", body: EmptyRequest())
        setAuthToken(response.token)
        logger.info("🔄 Token refreshed successfully")
        
        return response
    }
    
    // MARK: - Health Check
    func healthCheck() async throws -> HealthResponse {
        // Use direct HTTP request for health check to avoid token requirements
        guard let url = URL(string: "http://localhost:8000/health") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0 // Short timeout for health checks
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
            }
            
            guard httpResponse.statusCode == 200 else {
                throw APIError.serverError(httpResponse.statusCode, "Health check failed")
            }
            
            return try JSONDecoder().decode(HealthResponse.self, from: data)
        } catch {
            throw APIError.networkError(error)
        }
    }
}
