import Foundation
import os.log

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func get<T: Codable>(endpoint: String) async throws -> T
    func post<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T
    func put<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T
    func delete(endpoint: String) async throws
}

// MARK: - Real API Client
class APIClient: APIClientProtocol {
    static let shared = APIClient()
    
    private let session: URLSession
    private let logger = Logger(subsystem: "com.lyo.app", category: "APIClient")
    
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
        return try await request(endpoint: endpoint, method: .get)
    }
    
    func post<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T {
        return try await request(endpoint: endpoint, method: .post, body: body)
    }
    
    func put<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T {
        return try await request(endpoint: endpoint, method: .put, body: body)
    }
    
    func delete(endpoint: String) async throws {
        let _: EmptyResponse = try await request(endpoint: endpoint, method: .delete)
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
}

// MARK: - HTTP Methods
// HTTPMethod is defined in AIAvatarIntegration.swift to avoid duplication

// MARK: - Response Models
// ErrorResponse is defined in AIAvatarIntegration.swift to avoid duplication

// EmptyResponse is defined in AIAvatarIntegration.swift to avoid duplication

// MARK: - Health Response
struct HealthResponse: Codable {
    let status: String
    let message: String
    let timestamp: String
}

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

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