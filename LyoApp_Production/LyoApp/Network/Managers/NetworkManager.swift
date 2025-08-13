import Foundation
import Combine

// MARK: - Network Manager for LyoBackendJune Integration
@MainActor
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isConnected = true
    @Published var authToken: String?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = BackendConfig.timeoutInterval
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        // Network connectivity monitoring
        // Implementation would depend on your preferred network monitoring library
    }
    
    // MARK: - Generic Request Method
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:],
        responseType: T.Type
    ) async throws -> T {
        
        guard let url = URL(string: BackendConfig.fullBaseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add auth token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add custom headers
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // Debug logging
            print("📡 HTTP Response: \(httpResponse.statusCode) for \(url)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Response Data: \(responseString.prefix(200))...")
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                let decoded = try JSONDecoder().decode(responseType, from: data)
                return decoded
            case 401:
                throw NetworkError.unauthorized
            case 403:
                throw NetworkError.forbidden
            case 404:
                throw NetworkError.notFound
            case 500...599:
                throw NetworkError.serverError
            default:
                throw NetworkError.unknown(httpResponse.statusCode)
            }
            
        } catch {
            if error is DecodingError {
                throw NetworkError.decodingError
            } else if error is NetworkError {
                throw error
            } else {
                throw NetworkError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    func get<T: Codable>(endpoint: String, responseType: T.Type) async throws -> T {
        return try await request(endpoint: endpoint, method: .GET, responseType: responseType)
    }
    
    func post<T: Codable>(endpoint: String, body: Data, responseType: T.Type) async throws -> T {
        return try await request(endpoint: endpoint, method: .POST, body: body, responseType: responseType)
    }
    
    func put<T: Codable>(endpoint: String, body: Data, responseType: T.Type) async throws -> T {
        return try await request(endpoint: endpoint, method: .PUT, body: body, responseType: responseType)
    }
    
    func delete<T: Codable>(endpoint: String, responseType: T.Type) async throws -> T {
        return try await request(endpoint: endpoint, method: .DELETE, responseType: responseType)
    }
    
    // MARK: - Authentication
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    
    // MARK: - Health Check
    func healthCheck() async throws -> HealthResponse {
        return try await get(endpoint: BackendConfig.Endpoints.health, responseType: HealthResponse.self)
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT" 
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case networkError(String)
    case decodingError
    case unknown(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError:
            return "Failed to decode response"
        case .unknown(let code):
            return "Unknown error with code: \(code)"
        }
    }
}

// MARK: - Health Response Model
struct HealthResponse: Codable {
    let status: String
    let message: String?
    let timestamp: String
    let features: [String]?
}
