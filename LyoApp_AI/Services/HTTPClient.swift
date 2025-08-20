import Foundation
import Combine

// MARK: - HTTP Client Protocol
protocol HTTPClientProtocol {
    func request<T: Codable>(_ request: HTTPRequest, responseType: T.Type) async throws -> T
    func request(_ request: HTTPRequest) async throws
}

// MARK: - HTTP Request Structure
struct HTTPRequest {
    let method: HTTPMethod
    let url: URL
    let headers: [String: String]
    let body: Data?
    
    init(method: HTTPMethod, url: URL, headers: [String: String] = [:], body: Data? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

// MARK: - HTTP Errors
enum HTTPError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(Int, String?)
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case badRequest(String?)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Forbidden access"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Rate limit exceeded"
        case .badRequest(let message):
            return "Bad request: \(message ?? "Invalid request")"
        }
    }
}

// MARK: - Live HTTP Client Implementation
class LiveHTTPClient: HTTPClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let tokenProvider: TokenProvider
    
    init(baseURL: String = "http://localhost:8002", tokenProvider: TokenProvider) {
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL: \(baseURL)")
        }
        
        self.baseURL = url
        self.tokenProvider = tokenProvider
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    func request<T: Codable>(_ request: HTTPRequest, responseType: T.Type) async throws -> T {
        let data = try await performRequest(request)
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("🔍 Decoding Error: \(error)")
            print("🔍 Raw Data: \(String(data: data, encoding: .utf8) ?? "Invalid UTF8")")
            throw HTTPError.decodingError(error)
        }
    }
    
    func request(_ request: HTTPRequest) async throws {
        _ = try await performRequest(request)
    }
    
    private func performRequest(_ request: HTTPRequest) async throws -> Data {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        
        // Add default headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("LyoApp-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add custom headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add authentication if available
        if let token = tokenProvider.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPError.networkError(NSError(domain: "InvalidResponse", code: -1, userInfo: nil))
            }
            
            print("🌐 HTTP \(request.method.rawValue) \(request.url.path) -> \(httpResponse.statusCode)")
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 400:
                let message = String(data: data, encoding: .utf8)
                throw HTTPError.badRequest(message)
            case 401:
                // Clear invalid token and throw error
                tokenProvider.clearTokens()
                throw HTTPError.unauthorized
            case 403:
                throw HTTPError.forbidden
            case 404:
                throw HTTPError.notFound
            case 429:
                throw HTTPError.rateLimited
            case 500...599:
                let message = String(data: data, encoding: .utf8)
                throw HTTPError.serverError(httpResponse.statusCode, message)
            default:
                let message = String(data: data, encoding: .utf8)
                throw HTTPError.serverError(httpResponse.statusCode, message)
            }
            
        } catch let error as HTTPError {
            throw error
        } catch {
            throw HTTPError.networkError(error)
        }
    }
}

// MARK: - Token Provider
class TokenProvider: ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published var isAuthenticated: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "lyoapp_access_token"
    private let refreshTokenKey = "lyoapp_refresh_token"
    
    init() {
        loadTokens()
    }
    
    func setTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.isAuthenticated = true
        
        userDefaults.set(accessToken, forKey: accessTokenKey)
        userDefaults.set(refreshToken, forKey: refreshTokenKey)
        
        print("🔐 Tokens saved successfully")
    }
    
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        isAuthenticated = false
        
        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: refreshTokenKey)
        
        print("🔓 Tokens cleared")
    }
    
    private func loadTokens() {
        accessToken = userDefaults.string(forKey: accessTokenKey)
        refreshToken = userDefaults.string(forKey: refreshTokenKey)
        isAuthenticated = accessToken != nil
        
        if isAuthenticated {
            print("🔐 Tokens loaded from storage")
        }
    }
    
    func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw HTTPError.unauthorized
        }
        
        // This would typically make a request to refresh the token
        // For now, we'll clear tokens if refresh fails
        print("🔄 Token refresh needed - clearing tokens")
        clearTokens()
        throw HTTPError.unauthorized
    }
}

// MARK: - Request Builder Extensions
extension HTTPRequest {
    static func get(url: URL, headers: [String: String] = [:]) -> HTTPRequest {
        return HTTPRequest(method: .GET, url: url, headers: headers)
    }
    
    static func post<T: Codable>(url: URL, body: T? = nil, headers: [String: String] = [:]) throws -> HTTPRequest {
        var requestBody: Data? = nil
        
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            requestBody = try encoder.encode(body)
        }
        
        return HTTPRequest(method: .POST, url: url, headers: headers, body: requestBody)
    }
    
    static func post(url: URL, headers: [String: String] = [:]) -> HTTPRequest {
        return HTTPRequest(method: .POST, url: url, headers: headers, body: nil)
    }
    
    static func put<T: Codable>(url: URL, body: T, headers: [String: String] = [:]) throws -> HTTPRequest {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(body)
        return HTTPRequest(method: .PUT, url: url, headers: headers, body: data)
    }
    
    static func delete(url: URL, headers: [String: String] = [:]) -> HTTPRequest {
        return HTTPRequest(method: .DELETE, url: url, headers: headers)
    }
}

// MARK: - Mock HTTP Client for Testing
class MockHTTPClient: HTTPClientProtocol {
    var mockResponses: [String: Any] = [:]
    var shouldFail: Bool = false
    var failureError: HTTPError = .networkError(NSError(domain: "MockError", code: -1, userInfo: nil))
    
    func request<T>(_ request: HTTPRequest, responseType: T.Type) async throws -> T where T : Codable {
        if shouldFail {
            throw failureError
        }
        
        let key = "\(request.method.rawValue)_\(request.url.path)"
        
        if let mockData = mockResponses[key] as? T {
            return mockData
        }
        
        // Return mock data based on type
        if T.self == AuthResponse.self {
            let mockAuth = AuthResponse(
                accessToken: "mock_access_token",
                refreshToken: "mock_refresh_token",
                tokenType: "Bearer",
                expiresIn: 3600,
                user: User(
                    id: "mock_user_id",
                    email: "mock@example.com",
                    displayName: "Mock User",
                    profilePictureURL: nil,
                    isEmailVerified: true,
                    preferences: UserPreferences(
                        learningGoals: ["iOS Development"],
                        difficultyLevel: .intermediate,
                        studyReminders: true,
                        contentLanguage: "en"
                    ),
                    stats: UserStats(totalPoints: 150, streak: 5, completedCourses: 3),
                    createdAt: Date(),
                    lastActiveAt: Date()
                )
            )
            return mockAuth as! T
        }
        
        throw HTTPError.noData
    }
    
    func request(_ request: HTTPRequest) async throws {
        if shouldFail {
            throw failureError
        }
    }
}
