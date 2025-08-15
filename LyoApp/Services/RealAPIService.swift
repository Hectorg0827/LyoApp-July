import Foundation
import Network

// MARK: - API Response Models
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct ResetPasswordRequest: Codable {
    let email: String
}

struct EmptyResponse: Codable {}

// MARK: - Production API Service
@MainActor
class RealAPIService: ObservableObject {
    static let shared = RealAPIService()
    
    @Published var isOnline = true
    @Published var isLoading = false
    
    private let session: URLSession
    private let baseURL: String
    private let networkMonitor = NWPathMonitor()
    
    init() {
        // Production configuration
        #if DEBUG
        self.baseURL = "http://localhost:8000/api/v1"
        #else
        self.baseURL = "https://api.lyo.app/api/v1"
        #endif
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "User-Agent": "LyoApp/1.0 iOS"
        ]
        
        self.session = URLSession(configuration: config)
        
        setupNetworkMonitoring()
    }
    
    // MARK: - Response Models
    struct LearningResourceResponse: Codable {
        let resources: [LearningResource]
        let totalCount: Int
        let hasMore: Bool
        let nextOffset: Int?
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    // MARK: - Authentication
    func authenticate(email: String, password: String) async throws -> AuthResponse {
        let request = AuthRequest(email: email, password: password)
        return try await performRequest(
            endpoint: "/auth/login",
            method: "POST",
            body: request,
            responseType: AuthResponse.self
        )
    }
    
    func register(email: String, password: String, username: String, fullName: String?) async throws -> AuthResponse {
        let request = [
            "email": email,
            "password": password,
            "username": username,
            "fullName": fullName ?? ""
        ]
        
        return try await performRequest(
            endpoint: "/auth/register",
            method: "POST",
            body: request,
            responseType: AuthResponse.self
        )
    }
    
    // MARK: - Learning Resources
    func fetchResources(
        query: String? = nil,
        contentType: LearningResource.ContentType? = nil,
        difficulty: LearningResource.DifficultyLevel? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> LearningResourceResponse {
        var components = URLComponents(string: "\(baseURL)/learning-resources")!
        var queryItems: [URLQueryItem] = []
        
        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        if let contentType = contentType {
            queryItems.append(URLQueryItem(name: "type", value: contentType.rawValue))
        }
        if let difficulty = difficulty {
            queryItems.append(URLQueryItem(name: "difficulty", value: difficulty.rawValue))
        }
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        
        components.queryItems = queryItems
        
        return try await performRequest(
            endpoint: components.url!.path + "?" + (components.query ?? ""),
            method: "GET",
            body: Optional<String>.none,
            responseType: LearningResourceResponse.self
        )
    }
    
    func fetchLearningResources() async throws -> [LearningResource] {
        let response = try await fetchResources()
        return response.resources
    }
    
    func fetchResourceDetails(id: String) async throws -> LearningResource {
        return try await performRequest(
            endpoint: "/learning-resources/\(id)",
            method: "GET",
            body: Optional<String>.none,
            responseType: LearningResource.self
        )
    }
    
    // MARK: - User Progress
    func saveProgress(_ progress: LearningProgress) async throws {
        let _: EmptyResponse = try await performRequest(
            endpoint: "/users/progress",
            method: "POST",
            body: progress,
            responseType: EmptyResponse.self
        )
    }
    
    func getUserProgress() async throws -> [LearningProgress] {
        return try await performRequest(
            endpoint: "/users/progress",
            method: "GET",
            body: Optional<String>.none,
            responseType: [LearningProgress].self
        )
    }
    
    // MARK: - Recommendations
    func getRecommendations() async throws -> [LearningResource] {
        return try await performRequest(
            endpoint: "/recommendations",
            method: "GET",
            body: Optional<String>.none,
            responseType: [LearningResource].self
        )
    }
    
    // MARK: - User Management
    func getCurrentUser() async throws -> APIUserProfile {
        return try await performRequest(
            endpoint: "/users/me",
            method: "GET",
            body: Optional<String>.none,
            responseType: APIUserProfile.self
        )
    }
    
    func setAuthenticatedUser(_ user: User) {
        // Store user for session management
        // This could be expanded to include user-specific configuration
    }
    
    func updateProgress(
        resourceId: String,
        progress: Double,
        timeSpent: TimeInterval,
        isCompleted: Bool
    ) async throws {
        let progressData = [
            "resourceId": resourceId,
            "progress": progress,
            "timeSpent": timeSpent,
            "isCompleted": isCompleted
        ] as [String: Any]
        
        // Convert to data for request
        let jsonData = try JSONSerialization.data(withJSONObject: progressData)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/users/progress")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = KeychainManager.shared.retrieve(.authToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = jsonData
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw APIError.networkError(NSError(domain: "UpdateProgressError", code: -1))
        }
    }
    
    // MARK: - Token Management
    private func refreshToken() async throws {
        guard let refreshToken = KeychainManager.shared.retrieve(.refreshToken) else {
            throw APIError.noAuthToken
        }
        
        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
        
        let authResponse: AuthResponse = try await performRequest(
            endpoint: "/auth/refresh",
            method: "POST",
            body: refreshRequest,
            responseType: AuthResponse.self
        )
        
        // Store new tokens
        KeychainManager.shared.store(authResponse.accessToken, for: .authToken)
        KeychainManager.shared.store(authResponse.refreshToken, for: .refreshToken)
    }
    
    // MARK: - Generic Request Handler
    private func performRequest<T: Codable, R: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil,
        responseType: R.Type
    ) async throws -> R {
        // Update loading state
        isLoading = true
        defer { isLoading = false }
        
        // Build URL
        let url: URL
        if endpoint.starts(with: "http") {
            url = URL(string: endpoint)!
        } else {
            url = URL(string: baseURL + endpoint)!
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add auth token if available
        if let token = KeychainManager.shared.retrieve(.authToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // Perform request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            if responseType == EmptyResponse.self {
                return EmptyResponse() as! R
            }
            return try JSONDecoder().decode(responseType, from: data)
        case 400:
            // Bad request - could be invalid credentials or user already exists
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorData["message"] as? String {
                // Map to canonical errors
                if message.lowercased().contains("credential") || message.lowercased().contains("password") {
                    throw APIError.unauthorized
                } else if message.lowercased().contains("already exists") || message.lowercased().contains("duplicate") {
                    throw APIError.serverError(httpResponse.statusCode, message)
                }
            }
            throw APIError.serverError(httpResponse.statusCode, nil)
        case 401:
            // Try to refresh token
            if KeychainManager.shared.retrieve(.refreshToken) != nil {
                try await refreshToken()
                throw APIError.unauthorized
            } else {
                throw APIError.unauthorized
            }
        case 409:
            throw APIError.serverError(httpResponse.statusCode, "Conflict")
        case 429:
            throw APIError.rateLimitExceeded
        default:
            throw APIError.serverError(httpResponse.statusCode, nil)
        }
    }
}

// MARK: - API Models
struct AuthRequest: Codable {
    let email: String
    let password: String
}

struct APIUserProfile: Codable {
    let id: String
    let username: String
    let email: String
    let fullName: String?
    let profileImageURL: String?
}


