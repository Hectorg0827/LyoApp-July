import Foundation
import OSLog
import Network

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Client Error
enum APIClientError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case encodingFailed(Error)
    case serverError(Int, String?)
    case networkError(Error)
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Rate limited. Please try again later."
        case .timeout:
            return "Request timeout"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

// MARK: - API Client
@MainActor
final class APIClient: ObservableObject {
    static let shared = APIClient()
    
    // MARK: - Properties
    private let baseURL = APIEnvironment.current.base.absoluteString
    private let session: URLSession
    private let logger
    
    @Published var isLoading = false
    @Published var lastError: APIClientError?
    
    // Authentication - using UserDefaults for now (will be replaced with secure storage)
    private var tokenStore = UserDefaults.standard
    private var authToken: String? {
        get { tokenStore.string(forKey: "lyo_access_token") }
        set {
            if let token = newValue {
                tokenStore.set(token, forKey: "lyo_access_token")
            } else {
                tokenStore.removeObject(forKey: "lyo_access_token")
            }
        }
    }
    private var refreshToken: String? {
        get { tokenStore.string(forKey: "lyo_refresh_token") }
        set {
            if let token = newValue {
                tokenStore.set(token, forKey: "lyo_refresh_token")
            } else {
                tokenStore.removeObject(forKey: "lyo_refresh_token")
            }
        }
    }
    
    // Single-flight refresh guard
    private var isRefreshing = false
    
    // Current user cache
    @Published var currentUser: User?
    
    // MARK: - Initialization
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        logger.info("✅ APIClient initialized with backend: \(self.baseURL) (\(APIEnvironment.current.displayName))")
    }
    
    // MARK: - Authentication Management
    func setAuthToken(_ token: String, refreshToken: String? = nil, userId: String? = nil) {
        authToken = token
        
        if let refreshToken = refreshToken {
            self.refreshToken = refreshToken
        }
        
        if let userId = userId {
            tokenStore.set(userId, forKey: "lyo_user_id")
        }
        
        logger.info("🔐 Auth token updated")
    }
    
    func clearAuthTokens() {
        authToken = nil
        refreshToken = nil
        tokenStore.removeObject(forKey: "lyo_user_id")
        currentUser = nil
        logger.info("🔓 Auth tokens cleared")
    }
    
    // MARK: - Request Building
    private func buildRequest(endpoint: String, method: HTTPMethod, queryParams: [String: String] = [:]) throws -> URLRequest {
        // Normalize base and path to avoid malformed URLs
        let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let path = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        
        guard var components = URLComponents(string: "\(base)\(path)") else {
            throw APIClientError.invalidURL
        }
        
        if !queryParams.isEmpty {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            throw APIClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        // Versioned content types for contract stability
        request.setValue("application/json;v=1", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json;v=1", forHTTPHeaderField: "Accept")
        
        if let authToken = authToken, !authToken.isEmpty {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        request.setValue("LyoApp/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        
        return request
    }
    
    // MARK: - Network Requests
    func get<T: Decodable>(_ endpoint: String, query: [String: String] = [:]) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: .GET, queryParams: query)
        return try await performRequest(request)
    }
    
    func post<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: .POST)
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw APIClientError.encodingFailed(error)
        }
        return try await performRequest(request)
    }
    
    func put<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: .PUT)
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw APIClientError.encodingFailed(error)
        }
        return try await performRequest(request)
    }
    
    func delete<T: Decodable>(_ endpoint: String) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: .DELETE)
        return try await performRequest(request)
    }
    
    // MARK: - Token Refresh
    private func refreshAccessToken() async throws {
        guard let refreshToken = self.refreshToken, !refreshToken.isEmpty else {
            throw APIClientError.unauthorized
        }
        // prevent concurrent refreshes
        if isRefreshing {
            // Briefly wait for the in-flight refresh to complete
            try await Task.sleep(nanoseconds: 150_000_000)
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        
        logger.info("🔄 Refreshing access token")
        let requestBody = RefreshTokenRequest(refreshToken: refreshToken)
        let response: TokenRefreshResponse = try await post("/auth/refresh", body: requestBody)
        let newAccess = response.actualAccessToken
        let newRefresh = response.actualRefreshToken ?? refreshToken
        guard !newAccess.isEmpty else {
            throw APIClientError.unauthorized
        }
        setAuthToken(newAccess, refreshToken: newRefresh)
        logger.info("✅ Token refresh successful")
    }
    
    // MARK: - Request Execution
    private func performRequest<T: Decodable>(_ originalRequest: URLRequest) async throws -> T {
        logger.info("🌐 \(originalRequest.httpMethod ?? "GET") \(originalRequest.url?.absoluteString ?? "unknown")")
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, response) = try await session.data(for: originalRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIClientError.unknown
            }
            let status = httpResponse.statusCode
            
            logger.info("📡 Response: \(status)")
            
            switch status {
            case 200...299:
                break
            case 401:
                // Attempt refresh once, then retry original request
                do {
                    try await refreshAccessToken()
                    var retried = originalRequest
                    if let token = authToken, !token.isEmpty {
                        retried.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    }
                    let (retryData, retryResponse) = try await session.data(for: retried)
                    guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                        throw APIClientError.unknown
                    }
                    guard (200...299).contains(retryHTTP.statusCode) else {
                        let body = String(data: retryData, encoding: .utf8)
                        throw APIClientError.serverError(retryHTTP.statusCode, body)
                    }
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let result = try decoder.decode(T.self, from: retryData)
                    lastError = nil
                    return result
                } catch {
                    clearAuthTokens()
                    throw APIClientError.unauthorized
                }
            case 403:
                throw APIClientError.forbidden
            case 404:
                throw APIClientError.notFound
            case 408:
                throw APIClientError.timeout
            case 429:
                throw APIClientError.rateLimited
            case 400...499:
                let errorMessage = String(data: data, encoding: .utf8)
                throw APIClientError.serverError(status, errorMessage)
            case 500...599:
                let errorMessage = String(data: data, encoding: .utf8)
                throw APIClientError.serverError(status, errorMessage)
            default:
                throw APIClientError.unknown
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let result = try decoder.decode(T.self, from: data)
                lastError = nil
                return result
            } catch {
                logger.error("❌ Decoding error: \(error.localizedDescription)")
                throw APIClientError.decodingFailed(error)
            }
            
        } catch let error as APIClientError {
            lastError = error
            throw error
        } catch {
            let apiError = APIClientError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    // MARK: - Health Check
    func healthCheck() async throws -> SystemHealthResponse {
        return try await get("/health")
    }
    
    // MARK: - Authentication API
    func authenticate(email: String, password: String) async throws -> LoginResponse {
        let loginRequest = LoginRequest(email: email.sanitized, password: password)
        let response: LoginResponse = try await post("/auth/login", body: loginRequest)
        logger.info("✅ Real authentication successful")
        return response
    }
    
    func register(email: String, password: String, username: String, fullName: String) async throws -> LoginResponse {
        let registerRequest = RegisterRequest(
            email: email.sanitized,
            password: password,
            username: username.sanitized,
            fullName: fullName.sanitized
        )
        let response: LoginResponse = try await post("/auth/register", body: registerRequest)
        logger.info("✅ Real registration successful")
        return response
    }
    
    // MARK: - AI Content Generation
    func generateAIContent(prompt: String, maxTokens: Int = 1000) async throws -> AIGenerationResponse {
        let request = AIGenerationRequest(prompt: prompt.sanitized, maxTokens: maxTokens)
        let response: AIGenerationResponse = try await post("/ai/chat", body: request)
        logger.info("✅ Real AI content generated")
        return response
    }
    
    func checkAIStatus() async throws -> AIStatusResponse {
        let response: AIStatusResponse = try await get("/ai/status")
        logger.info("✅ AI service status: \(response.status)")
        return response
    }
    
    // MARK: - Feed API
    func loadFeed(page: Int = 1, limit: Int = 20) async throws -> FeedResponse {
        let params = [
            "page": String(page),
            "limit": String(limit)
        ]
        let backendResponse: BackendFeedResponse = try await get("/feed", query: params)
        let response = backendResponse.toFeedResponse()
        logger.info("✅ Real feed data loaded: \(response.posts.count) posts")
        return response
    }
    
    // MARK: - User Management API
    func getCurrentUser() async throws -> UserProfile {
        let response: UserProfile = try await get("/user/profile")
        logger.info("✅ Real user profile loaded")
        return response
    }
    
    func login(email: String, password: String) async throws -> LoginResponse {
        let loginData = [
            "email": email,
            "password": password
        ]
        let response: LoginResponse = try await post("/auth/login", body: loginData)
        let backendUser = response.user
        currentUser = User(
            id: backendUser.id,
            username: backendUser.username,
            email: backendUser.email ?? "",
            fullName: backendUser.fullName,
            avatarUrl: backendUser.avatarUrl,
            level: backendUser.isVerified ? 5 : 1
        )
        setAuthToken(response.actualAccessToken, refreshToken: response.refreshToken, userId: backendUser.id)
        logger.info("✅ Backend login successful")
        return response
    }
    
    func updateProgress(_ resourceId: String, _ completionData: Any?, _ progressType: String, _ timeSpent: Int) async throws -> ProgressUpdateResponse {
        let request = ProgressUpdateRequest(resourceId: resourceId, progressType: progressType, timeSpent: timeSpent)
        let response: ProgressUpdateResponse = try await post("/progress/update", body: request)
        logger.info("✅ Progress updated for resource: \(resourceId)")
        return response
    }

    // MARK: - Learning Resources API
    func fetchLearningResources(query: String? = nil, limit: Int = 20) async throws -> LearningResourcesResponse {
        var queryParams: [String: String] = ["limit": String(limit)]
        if let query = query?.sanitized {
            queryParams["q"] = query
        }
        let backendResponse: CoursesResponse = try await get("/courses", query: queryParams)
        let response = backendResponse.toLearningResourcesResponse()
        logger.info("✅ Real courses loaded: \(response.resources.count) resources")
        return response
    }
    
    func enrollInLearningResource(resourceId: String) async throws -> EnrollmentResponse {
        let response: EnrollmentResponse = try await post("/courses/\(resourceId)/enroll", body: APIEmptyRequest())
        logger.info("✅ Successfully enrolled in resource: \(resourceId)")
        return response
    }
    
    func unenrollFromLearningResource(resourceId: String) async throws -> EnrollmentResponse {
        let response: EnrollmentResponse = try await delete("/courses/\(resourceId)/enroll")
        logger.info("✅ Successfully unenrolled from resource: \(resourceId)")
        return response
    }
    
    // MARK: - System Health & Connection
    func getSystemHealth() async throws -> SystemHealthResponse {
        return try await get("/health")
    }
    
    func checkConnection() async throws -> Bool {
        do {
            let _: SystemHealthResponse = try await get("/health")
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Social Actions API
    func likePost(_ postId: String) async throws -> LikePostResponse {
        let response: LikePostResponse = try await post("/posts/\(postId)/like", body: APIEmptyRequest())
        logger.info("👍 Post \(postId) liked via backend: \(response.isLiked)")
        return response
    }
    
    func commentOnPost(_ postId: String, comment: String) async throws -> CommentResponse {
        let request = CommentRequest(postId: postId, content: comment)
        let response: CommentResponse = try await post("/posts/\(postId)/comments", body: request)
        logger.info("💬 Commented on post \(postId)")
        return response
    }
    
    func sharePost(_ postId: String) async throws -> ShareResponse {
        let response: ShareResponse = try await post("/posts/\(postId)/share", body: APIEmptyRequest())
        logger.info("🔄 Post \(postId) shared via backend")
        return response
    }
    
    func createPost(_ content: String, mediaUrls: [String] = []) async throws -> CreatePostResponse {
        let request = CreatePostRequest(content: content, mediaUrls: mediaUrls)
        let response: CreatePostResponse = try await post("/posts", body: request)
        logger.info("📝 Created post via backend")
        return response
    }
    
    // MARK: - User Management API
    func getUserProfile(_ userId: String? = nil) async throws -> UserProfileResponse {
        let endpoint = userId != nil ? "/users/\(userId!)" : "/users/profile"
        let response: UserProfileResponse = try await get(endpoint)
        logger.info("👤 Retrieved user profile via backend")
        return response
    }
    
    func updateUserProfile(_ profile: UpdateUserProfileRequest) async throws -> UserProfileResponse {
        let response: UserProfileResponse = try await put("/users/profile", body: profile)
        logger.info("👤 Updated user profile via backend")
        return response
    }
    
    func followUser(_ userId: String) async throws -> FollowResponse {
        let response: FollowResponse = try await post("/users/\(userId)/follow", body: APIEmptyRequest())
        logger.info("👥 Followed user \(userId) via backend")
        return response
    }
    
    func unfollowUser(_ userId: String) async throws -> FollowResponse {
        let response: FollowResponse = try await delete("/users/\(userId)/follow")
        logger.info("👥 Unfollowed user \(userId) via backend")
        return response
    }
    
    // MARK: - Search API
    func searchUsers(_ query: String, limit: Int = 20) async throws -> [User] {
        let params = ["q": query, "limit": String(limit)]
        let response: SearchUsersResponse = try await get("/search/users", query: params)
        logger.info("🔍 Searched users for '\(query)' via backend")
        
        // Convert backend response to canonical User model
        return response.users.map { backendUser in
            User(
                id: backendUser.id,
                username: backendUser.username,
                email: backendUser.email ?? "",
                fullName: backendUser.fullName,
                avatarUrl: backendUser.avatarUrl,
                level: backendUser.isVerified ? 5 : 1
            )
        }
    }
    
    func searchContent(_ query: String, limit: Int = 20) async throws -> [FeedItem] {
        let params = ["q": query, "limit": String(limit)]
        let response: SearchContentResponse = try await get("/search/content", query: params)
        logger.info("🔍 Searched content for '\(query)' via backend")
        
        // Convert backend response to canonical FeedItem model
        return response.posts.compactMap { backendItem -> FeedItem? in
            let isoFormatter = ISO8601DateFormatter()
            guard let timestamp = isoFormatter.date(from: backendItem.createdAt) else {
                return nil
            }
            
            let creator = User(
                id: backendItem.author.id,
                username: backendItem.author.username,
                email: "",
                fullName: backendItem.author.displayName,
                avatarUrl: backendItem.author.avatarUrl,
                level: backendItem.author.isVerified ? 5 : 1
            )
            
            let contentType: FeedContentType
            switch backendItem.type.lowercased() {
            case "video":
                contentType = .video(VideoContent(
                    url: URL(string: backendItem.mediaUrl ?? "") ?? URL(fileURLWithPath: ""),
                    thumbnailURL: URL(string: backendItem.thumbnailUrl ?? "") ?? URL(fileURLWithPath: ""),
                    title: backendItem.title,
                    description: backendItem.content ?? "",
                    quality: .hd,
                    duration: 120
                ))
            default:
                contentType = .article(ArticleContent(
                    title: backendItem.title,
                    excerpt: backendItem.content ?? "",
                    content: backendItem.content ?? "",
                    heroImageURL: URL(string: backendItem.thumbnailUrl ?? ""),
                    readTime: 300
                ))
            }
            
            return FeedItem(
                id: UUID(),
                creator: creator,
                contentType: contentType,
                timestamp: timestamp,
                engagement: EngagementMetrics(
                    likes: backendItem.engagement.likes,
                    comments: backendItem.engagement.comments,
                    shares: backendItem.engagement.shares,
                    saves: backendItem.engagement.saves,
                    isLiked: backendItem.engagement.isLiked,
                    isSaved: backendItem.engagement.isSaved
                ),
                duration: nil
            )
        }
    }
    // ✅ Duplicate feed functions removed - using original definitions above
}

// ✅ Models moved to APIResponseModels.swift to avoid duplicates

// MARK: - String Extensions
extension String {
    var sanitized: String {
        var sanitized = self
        
        let dangerousChars = CharacterSet(charactersIn: "<>\"'&")
        sanitized = sanitized.components(separatedBy: dangerousChars).joined()
        
        if sanitized.count > 1000 {
            sanitized = String(sanitized.prefix(1000))
        }
        
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return sanitized
    }
}
