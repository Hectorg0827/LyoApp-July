import Foundation
import Combine

/// Production-ready network manager that replaces SimpleNetworkManager
/// Uses the sophisticated Core/Networking infrastructure
@MainActor
public class NetworkManager: ObservableObject {
    public static let shared = NetworkManager()
    
    // MARK: - Published Properties
    @Published public var isInitialized = false
    @Published public var isConnected = true
    @Published public var isAuthenticated = false
    @Published public var currentUser: User?
    @Published public var lastError: NetworkError?
    
    // MARK: - Private Properties
    private let authManager: AuthManager
    private var apiClient: APIClient
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private var cancellables = Set<AnyCancellable>()
    
    public init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
        self.authManager = AuthManager(apiClient: apiClient)
        // Configure URLSession for production
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        self.session = URLSession(configuration: config)
        
        // Configure JSON coders
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        
        // Initialize API client
        apiClient = APIClient(environment: APIEnvironment.current, authManager: authManager)
        
        print("🌐 Production NetworkManager initialized")
    }
    
    func initialize() async {
        await checkConnectivity()
        await checkAuthStatus()
        isInitialized = true
        print("✅ NetworkManager initialization complete")
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async throws -> User {
        struct LoginRequest: Codable {
            let email: String
            let password: String
        }
        
        struct LoginResponse: Codable {
            let user: User
            let accessToken: String
            let refreshToken: String
            let expiresIn: Int
        }
        
        do {
            let response: LoginResponse = try await apiClient.post(
                "auth/login", 
                body: LoginRequest(email: email, password: password)
            )
            
            // Store tokens securely
            await authManager.setTokens(access: response.accessToken, refresh: response.refreshToken)
            
            // Update state
            currentUser = response.user
            isAuthenticated = true
            
            print("✅ Login successful for user: \(response.user.username)")
            return response.user
            
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    func register(email: String, password: String, fullName: String) async throws -> User {
        struct RegisterRequest: Codable {
            let email: String
            let password: String
            let fullName: String
        }
        
        struct RegisterResponse: Codable {
            let user: User
            let accessToken: String
            let refreshToken: String
            let expiresIn: Int
        }
        
        do {
            let response: RegisterResponse = try await apiClient.post(
                "auth/register",
                body: RegisterRequest(email: email, password: password, fullName: fullName)
            )
            
            // Store tokens securely
            await authManager.setTokens(access: response.accessToken, refresh: response.refreshToken)
            
            // Update state
            currentUser = response.user
            isAuthenticated = true
            
            print("✅ Registration successful for user: \(response.user.username)")
            return response.user
            
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    func logout() async {
        do {
            // Call logout endpoint
            try await apiClient.post("auth/logout", body: EmptyBody())
        } catch {
            print("⚠️ Logout API call failed: \(error)")
            // Continue with local logout even if API call fails
        }
        
        // Clear tokens and state
        await authManager.clearTokens()
        currentUser = nil
        isAuthenticated = false
        
        print("🔓 User logged out")
    }
    
    private func checkAuthStatus() async {
        let authenticated = await authManager.isAuthenticated
        if authenticated {
            await fetchCurrentUser()
        }
        isAuthenticated = authenticated
    }
    
    private func fetchCurrentUser() async {
        do {
            let user: User = try await apiClient.get("users/me")
            currentUser = user
            isAuthenticated = true
        } catch {
            // Token might be expired, let AuthManager handle refresh
            print("⚠️ Failed to fetch current user: \(error)")
        }
    }
    
    // MARK: - Feed Operations
    
    func fetchHomeFeed(page: Int = 1, limit: Int = 20) async throws -> FeedResponse {
        struct FeedResponse: Codable {
            let posts: [VideoPost]
            let hasMore: Bool
            let nextPage: Int?
        }
        
        do {
            let response: FeedResponse = try await apiClient.get("feed?page=\(page)&limit=\(limit)")
            return response
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    func createPost(title: String, content: String, videoURL: String?, thumbnailURL: String?) async throws -> VideoPost {
        struct CreatePostRequest: Codable {
            let title: String
            let content: String
            let videoURL: String?
            let thumbnailURL: String?
        }
        
        do {
            let post: VideoPost = try await apiClient.post(
                "posts",
                body: CreatePostRequest(title: title, content: content, videoURL: videoURL, thumbnailURL: thumbnailURL)
            )
            
            print("✅ Post created: \(post.title)")
            return post
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    func likePost(_ postId: UUID) async throws {
        do {
            try await apiClient.post("posts/\(postId.uuidString)/like", body: EmptyBody())
            print("👍 Post liked: \(postId)")
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    // MARK: - Course Operations
    
    func fetchCourses(page: Int = 1, limit: Int = 20) async throws -> CoursesResponse {
        struct CoursesResponse: Codable {
            let courses: [Course]
            let hasMore: Bool
            let nextPage: Int?
        }
        
        do {
            let response: CoursesResponse = try await apiClient.get("courses?page=\(page)&limit=\(limit)")
            return response
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    func fetchCourse(id: UUID) async throws -> Course {
        do {
            let course: Course = try await apiClient.get("courses/\(id.uuidString)")
            return course
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    func enrollInCourse(_ courseId: UUID) async throws {
        do {
            try await apiClient.post("courses/\(courseId.uuidString)/enroll", body: EmptyBody())
            print("📚 Enrolled in course: \(courseId)")
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    func updateCourseProgress(_ courseId: UUID, progress: Double) async throws {
        struct ProgressRequest: Codable {
            let progress: Double
        }
        
        do {
            try await apiClient.put(
                "courses/\(courseId.uuidString)/progress",
                body: ProgressRequest(progress: progress)
            )
            print("📈 Updated course progress: \(courseId) - \(Int(progress * 100))%")
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    // MARK: - Educational Content
    
    func fetchEducationalVideos(page: Int = 1, limit: Int = 20) async throws -> EducationalVideosResponse {
        struct EducationalVideosResponse: Codable {
            let videos: [EducationalVideo]
            let hasMore: Bool
            let nextPage: Int?
        }
        
        do {
            let response: EducationalVideosResponse = try await apiClient.get("educational/videos?page=\(page)&limit=\(limit)")
            return response
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    func fetchEbooks(page: Int = 1, limit: Int = 20) async throws -> EbooksResponse {
        struct EbooksResponse: Codable {
            let ebooks: [Ebook]
            let hasMore: Bool
            let nextPage: Int?
        }
        
        do {
            let response: EbooksResponse = try await apiClient.get("educational/ebooks?page=\(page)&limit=\(limit)")
            return response
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    // MARK: - User Profile
    
    func updateProfile(_ profile: UserProfileUpdate) async throws -> User {
        do {
            let user: User = try await apiClient.put("users/profile", body: profile)
            currentUser = user
            print("✅ Profile updated for: \(user.username)")
            return user
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    func uploadAvatar(_ imageData: Data) async throws -> User {
        // This would typically use multipart/form-data
        // For now, implementing with base64 encoding
        struct AvatarRequest: Codable {
            let imageData: String
        }
        
        let base64Image = imageData.base64EncodedString()
        
        do {
            let user: User = try await apiClient.post(
                "users/avatar",
                body: AvatarRequest(imageData: base64Image)
            )
            
            currentUser = user
            print("✅ Avatar updated for: \(user.username)")
            return user
        } catch {
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    // MARK: - Health Check
    
    func healthCheck() async throws -> HealthResponse {
        struct HealthResponse: Codable {
            let status: String
            let version: String
            let timestamp: Date
        }
        
        do {
            let response: HealthResponse = try await apiClient.get("health")
            isConnected = response.status == "healthy"
            return response
        } catch {
            isConnected = false
            lastError = error as? NetworkError ?? .unknown(error)
            throw error
        }
    }
    
    // MARK: - Analytics
    
    func trackEvent(_ event: AnalyticsEvent) async {
        do {
            try await apiClient.post("analytics/events", body: event)
        } catch {
            print("⚠️ Failed to track analytics event: \(error)")
            // Don't throw - analytics failures shouldn't break the app
        }
    }
    
    // MARK: - Connectivity Check
    
    private func checkConnectivity() async {
        do {
            _ = try await healthCheck()
            isConnected = true
        } catch {
            isConnected = false
            print("🔴 Connectivity check failed: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum NetworkError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case noConnection
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "Server error: \(code)"
        case .serverError(let message):
            return message
        case .noConnection:
            return "No internet connection"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

struct EmptyBody: Codable {}

struct UserProfileUpdate: Codable {
    let fullName: String?
    let bio: String?
    let location: String?
    let website: String?
}

struct AnalyticsEvent: Codable {
    let name: String
    let properties: [String: String]
    let timestamp: Date
    let userId: UUID?
    
    init(name: String, properties: [String: Any] = [:], userId: UUID? = nil) {
        self.name = name
        self.properties = properties.compactMapValues { "\($0)" }
        self.timestamp = Date()
        self.userId = userId
    }
}

// MARK: - Response Types

private struct FeedResponse: Codable {
    let posts: [VideoPost]
    let hasMore: Bool
    let nextPage: Int?
}

private struct CoursesResponse: Codable {
    let courses: [Course]
    let hasMore: Bool
    let nextPage: Int?
}

private struct EducationalVideosResponse: Codable {
    let videos: [EducationalVideo]
    let hasMore: Bool
    let nextPage: Int?
}

private struct EbooksResponse: Codable {
    let ebooks: [Ebook]
    let hasMore: Bool
    let nextPage: Int?
}
