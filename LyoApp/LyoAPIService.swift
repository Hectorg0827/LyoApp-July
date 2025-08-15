import Foundation
import Combine
import SwiftUI

// Local HTTPMethod enum for LyoAPIService
enum LyoHTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

/// Enhanced API service for Lyo AI Learn Buddy backend integration
@MainActor
class LyoAPIService: ObservableObject {
    // Singleton instance
    static let shared = LyoAPIService()
    
    // MARK: - Configuration
    #if DEBUG
    private let baseURL = "http://localhost:8000"
    #else
    private let baseURL = "https://api.lyoapp.com"
    #endif
    private let session = URLSession.shared
    
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
    
    // Private initializer to enforce singleton pattern
    private init() {
        // Initialize without APIClient dependency for now
        // Will implement backend integration methods directly
        checkAuthentication()
        checkConnection()
    }
    
    private func checkAuthentication() {
        if let _ = authToken, let _ = currentUserId {
            isAuthenticated = true
            // TODO: Fetch current user data from backend
        }
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
            throw APIError.serverError(httpResponse.statusCode, nil)
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
            throw APIError.serverError(httpResponse.statusCode, nil)
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
    
    func register(fullName: String, username: String, email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await performRegistration(
                fullName: fullName,
                username: username, 
                email: email,
                password: password
            )
            
            currentUser = response.user
            isAuthenticated = true
            lastError = nil
            
            // Store auth info
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
    
    private func performRegistration(fullName: String, username: String, email: String, password: String) async throws -> LoginResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/register") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let registrationData = [
            "full_name": fullName,
            "username": username,
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: registrationData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
        }
        
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            // Try to parse error message from response
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let _ = errorData["message"] as? String {
                throw APIError.serverError(httpResponse.statusCode, nil)
            }
            throw APIError.serverError(httpResponse.statusCode, nil)
        }
        
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }

    private func tryNextHealthEndpoint(endpoints: [String], index: Int) {
        guard index < endpoints.count else {
            // All endpoints failed
            DispatchQueue.main.async {
                self.isConnected = false
                // Map to a canonical error without using a String associated value
                self.lastError = .serverError(0, "Backend server not reachable at \(self.baseURL). Please start your backend server.")
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
        
        session.dataTask(with: request) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let self = self else { return }
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self.isConnected = true
                    self.lastError = nil
                    print("✅ Connected to backend at: \(url.absoluteString)")
                }
            } else {
                // Try next endpoint on main actor
                Task { @MainActor in
                    self.tryNextHealthEndpoint(endpoints: endpoints, index: index + 1)
                }
            }
        }.resume()
    }
    
    // Set auth token for compatibility with AppState
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
    
    // MARK: - API Methods
    
    /// Generate course outline based on topic and user preferences
    func generateCourseOutline(
        title: String,
        description: String,
        targetAudience: String,
        learningObjectives: [String],
        difficultyLevel: String,
        estimatedDurationHours: Int
    ) async throws -> CourseGenerationResponse {
        let request = CourseOutlineRequest(
            title: title,
            description: description,
            targetAudience: targetAudience,
            learningObjectives: learningObjectives,
            difficultyLevel: difficultyLevel,
            estimatedDurationHours: estimatedDurationHours
        )
        
        return try await performRequest(
            endpoint: "/api/v1/ai/curriculum/course-outline",
            method: .POST,
            body: request,
            responseType: CourseGenerationResponse.self
        )
    }
    
    /// Send message to AI mentor
    func sendMessageToMentor(
        message: String,
        context: [String: Any]? = nil
    ) async throws -> MentorResponse {
        let request = MentorMessageRequest(
            message: message,
            context: context
        )
        
        return try await performRequest(
            endpoint: "/api/v1/ai/mentor/conversation",
            method: .POST,
            body: request,
            responseType: MentorResponse.self
        )
    }
    
    /// Get conversation history with mentor
    func getConversationHistory(limit: Int = 20) async throws -> ConversationHistoryResponse {
        let endpoint = "/api/v1/ai/mentor/history?limit=\(limit)"
        
        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            body: nil as EmptyRequest?,
            responseType: ConversationHistoryResponse.self
        )
    }
    
    /// Generate lesson content
    func generateLessonContent(
        courseId: String,
        lessonTitle: String,
        lessonDescription: String,
        learningObjectives: [String],
        contentType: String,
        difficultyLevel: String
    ) async throws -> LessonContentResponse {
        let request = LessonContentRequest(
            courseId: courseId,
            lessonTitle: lessonTitle,
            lessonDescription: lessonDescription,
            learningObjectives: learningObjectives,
            contentType: contentType,
            difficultyLevel: difficultyLevel
        )
        
        return try await performRequest(
            endpoint: "/api/v1/ai/curriculum/lesson-content",
            method: .POST,
            body: request,
            responseType: LessonContentResponse.self
        )
    }
    
    /// Get AI system health status
    func getSystemHealth() async throws -> AIHealthResponse {
        return try await performRequest(
            endpoint: "/health",
            method: .GET,
            body: nil as EmptyRequest?,
            responseType: AIHealthResponse.self
        )
    }
    
    /// Get feed content for home screen
    func getFeedContent(page: Int = 0, limit: Int = 20) async throws -> FeedResponse {
        let endpoint = "/api/v1/feed?page=\(page)&limit=\(limit)"
        
        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            body: nil as EmptyRequest?,
            responseType: FeedResponse.self
        )
    }
    
    /// Get user posts for profile
    func getUserPosts(userId: String, page: Int = 0, limit: Int = 20) async throws -> UserPostsResponse {
        let endpoint = "/api/v1/users/\(userId)/posts?page=\(page)&limit=\(limit)"
        
        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            body: nil as EmptyRequest?,
            responseType: UserPostsResponse.self
        )
    }
    
    /// Returns backend health status for ErrorHandlingService
    public func getLegacySystemHealth() async throws -> [String: Any] {
        return try await self.performHealthCheck()
    }
    
    /// Rate an interaction
    func rateInteraction(interactionId: String, wasHelpful: Bool) async throws {
        let request = InteractionRatingRequest(
            interactionId: interactionId,
            wasHelpful: wasHelpful
        )
        
        let _: EmptyResponse = try await performRequest(
            endpoint: "/api/v1/ai/mentor/rate",
            method: .POST,
            body: request,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Generic Request Handler
    
    private func performRequest<T: Codable, R: Codable>(
        endpoint: String,
        method: LyoHTTPMethod,
        body: T? = nil,
        responseType: R.Type
    ) async throws -> R {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                    throw APIError.decodingError(error)
            }
        }
        
        // Update loading state
        isLoading = true
        lastError = nil
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Update loading state
            isLoading = false
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode response
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let result = try decoder.decode(responseType, from: data)
                    return result
                } catch {
                    print("Decoding error: \(error)")
                    throw APIError.decodingError(error)
                }
                
            case 400:
                throw APIError.serverError(400, nil)
            case 401:
                throw APIError.unauthorized
            case 403:
                throw APIError.serverError(403, nil)
            case 404:
                throw APIError.serverError(404, nil)
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode, nil)
            default:
                throw APIError.serverError(httpResponse.statusCode, "Unknown error")
            }
            
        } catch {
            isLoading = false
            if let apiError = error as? APIError {
                lastError = apiError
                throw apiError
            } else {
                lastError = .networkError(error)
                throw APIError.networkError(error)
            }
        }
    }
}

// MARK: - HTTP Method Enum

// HTTPMethod is defined in NetworkLayer.swift

// MARK: - API Error Types
// APIError is defined in AIAvatarIntegration.swift to avoid duplication

// MARK: - Request Models

struct EmptyRequest: Codable {
    // Empty request for GET endpoints
}

struct CourseOutlineRequest: Codable {
    let title: String
    let description: String
    let targetAudience: String
    let learningObjectives: [String]
    let difficultyLevel: String
    let estimatedDurationHours: Int
}

struct MentorMessageRequest: Codable {
    let message: String
    let context: [String: String]?
    
    init(message: String, context: [String: Any]? = nil) {
        self.message = message
        // Convert Any values to String for JSON serialization
        self.context = context?.compactMapValues { "\($0)" }
    }
}

struct LessonContentRequest: Codable {
    let courseId: String
    let lessonTitle: String
    let lessonDescription: String
    let learningObjectives: [String]
    let contentType: String
    let difficultyLevel: String
}

struct InteractionRatingRequest: Codable {
    let interactionId: String
    let wasHelpful: Bool
}

// MARK: - Response Models

struct CourseGenerationResponse: Codable {
    let taskId: String
    let status: String
    let userId: Int?
    let timestamp: String
    let outline: CourseOutlineData?
    let title: String
    let description: String
    let difficultyLevel: String
    let estimatedDurationHours: Int
    let targetAudience: String
    let learningObjectives: [String]
    let processingTimeMs: Double?
    let modelUsed: String?
    
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status
        case userId = "user_id"
        case timestamp
        case outline
        case title
        case description
        case difficultyLevel = "difficulty_level"
        case estimatedDurationHours = "estimated_duration_hours"
        case targetAudience = "target_audience"
        case learningObjectives = "learning_objectives"
        case processingTimeMs = "processing_time_ms"
        case modelUsed = "model_used"
    }
}

struct CourseOutlineData: Codable {
    let lessons: [LessonData]
    let personalizationApplied: PersonalizationData?
    
    enum CodingKeys: String, CodingKey {
        case lessons
        case personalizationApplied = "personalization_applied"
    }
}

struct LessonData: Codable {
    let title: String
    let description: String
    let topics: [String]
    let activities: [String]
    let contentType: String
    let outcomes: [String]
    let estimatedDuration: Int?
    let visualAids: String?
    let interactiveElements: String?
    let writtenAssignments: String?
    let practicalExercises: String?
    let contentFormat: String?
    let recommendedDuration: Int?
    let suggestedBreaks: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case topics
        case activities
        case contentType = "content_type"
        case outcomes
        case estimatedDuration = "estimated_duration"
        case visualAids = "visual_aids"
        case interactiveElements = "interactive_elements"
        case writtenAssignments = "written_assignments"
        case practicalExercises = "practical_exercises"
        case contentFormat = "content_format"
        case recommendedDuration = "recommended_duration"
        case suggestedBreaks = "suggested_breaks"
    }
}

struct PersonalizationData: Codable {
    let learningStyle: String
    let difficultyAdjusted: Double
    let sessionOptimized: Bool
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case learningStyle = "learning_style"
        case difficultyAdjusted = "difficulty_adjusted"
        case sessionOptimized = "session_optimized"
        case timestamp
    }
}

struct MentorResponse: Codable {
    let response: String
    let confidence: Double
    let engagementLevel: String
    let suggestedActions: [String]
    let interactionId: String
    let timestamp: String
    let processingTimeMs: Double?
    let modelUsed: String?
    
    enum CodingKeys: String, CodingKey {
        case response
        case confidence
        case engagementLevel = "engagement_level"
        case suggestedActions = "suggested_actions"
        case interactionId = "interaction_id"
        case timestamp
        case processingTimeMs = "processing_time_ms"
        case modelUsed = "model_used"
    }
}

struct ConversationHistoryResponse: Codable {
    let userId: Int
    let totalInteractions: Int
    let conversations: [ConversationData]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case totalInteractions = "total_interactions"
        case conversations
    }
}

struct ConversationData: Codable {
    let id: String
    let userMessage: String?
    let mentorResponse: String
    let timestamp: String
    let interactionType: String
    let wasHelpful: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userMessage = "user_message"
        case mentorResponse = "mentor_response"
        case timestamp
        case interactionType = "interaction_type"
        case wasHelpful = "was_helpful"
    }
}

struct LessonContentResponse: Codable {
    let taskId: String
    let status: String
    let courseId: String
    let lessonTitle: String
    let userId: Int?
    let timestamp: String
    let content: LessonContent?
    let contentType: String
    let difficultyLevel: String
    let processingTimeMs: Double?
    let modelUsed: String?
    
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status
        case courseId = "course_id"
        case lessonTitle = "lesson_title"
        case userId = "user_id"
        case timestamp
        case content
        case contentType = "content_type"
        case difficultyLevel = "difficulty_level"
        case processingTimeMs = "processing_time_ms"
        case modelUsed = "model_used"
    }
}

struct AIHealthResponse: Codable {
    let status: String
    let timestamp: String
    let models: [String: ModelStatus]
    let costStatus: CostStatus
    let overallPerformance: PerformanceData
    
    enum CodingKeys: String, CodingKey {
        case status
        case timestamp
        case models
        case costStatus = "cost_status"
        case overallPerformance = "overall_performance"
    }
}

struct ModelStatus: Codable {
    let status: String
    let responseTime: Double
    let errorRate: Double
    let circuitBreakerOpen: Bool
    
    enum CodingKeys: String, CodingKey {
        case status
        case responseTime = "response_time"
        case errorRate = "error_rate"
        case circuitBreakerOpen = "circuit_breaker_open"
    }
}

struct CostStatus: Codable {
    let current: Double
    let limit: Double
    let percentage: Double
}

struct PerformanceData: Codable {
    let responseTimeP95: Double
    let successRate: Double
    let activeConnections: Int
    
    enum CodingKeys: String, CodingKey {
        case responseTimeP95 = "response_time_p95"
        case successRate = "success_rate"
        case activeConnections = "active_connections"
    }
}

// MARK: - Feed API Response Models

struct FeedResponse: Codable {
    let items: [FeedItemResponse]
    let page: Int
    let totalPages: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case items
        case page
        case totalPages = "total_pages"
        case hasMore = "has_more"
    }
}

struct FeedItemResponse: Codable {
    let id: String
    let type: String // "video", "article", "post"
    let title: String
    let content: String?
    let mediaUrl: String?
    let thumbnailUrl: String?
    let author: FeedAuthor
    let engagement: FeedEngagement
    let createdAt: String
    let tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, content, tags
        case mediaUrl = "media_url"
        case thumbnailUrl = "thumbnail_url"
        case author, engagement
        case createdAt = "created_at"
    }
}

struct FeedAuthor: Codable {
    let id: String
    let username: String
    let displayName: String
    let avatarUrl: String?
    let isVerified: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case isVerified = "is_verified"
    }
}

struct FeedEngagement: Codable {
    let likes: Int
    let comments: Int
    let shares: Int
    let saves: Int
    let isLiked: Bool
    let isSaved: Bool
    
    enum CodingKeys: String, CodingKey {
        case likes, comments, shares, saves
        case isLiked = "is_liked"
        case isSaved = "is_saved"
    }
}

struct UserPostsResponse: Codable {
    let posts: [FeedItemResponse]
    let page: Int
    let totalPages: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case posts, page
        case totalPages = "total_pages"
        case hasMore = "has_more"
    }
}

// MARK: - API Service Extensions

extension LyoAPIService {
    /// Convert backend lesson data to frontend LessonContent
    func convertToLessonContent(from lessonData: LessonData) -> LessonContent {
        var blocks: [LessonBlock] = []
        var order = 0
        
        // Add title as heading
        blocks.append(LessonBlock(
            id: UUID(),
            type: .heading,
            data: .heading(HeadingData(text: lessonData.title, level: 1, style: .normal)),
            order: order
        ))
        order += 1
        
        // Add description as paragraph
        blocks.append(LessonBlock(
            id: UUID(),
            type: .paragraph,
            data: .paragraph(ParagraphData(text: lessonData.description, style: .normal)),
            order: order
        ))
        order += 1
        
        // Add topics as bullet list
        if !lessonData.topics.isEmpty {
            let listItems = lessonData.topics.map { ListItem(text: $0, subItems: nil) }
            blocks.append(LessonBlock(
                id: UUID(),
                type: .bulletList,
                data: .bulletList(BulletListData(items: listItems, style: .bullet)),
                order: order
            ))
            order += 1
        }
        
        // Add activities as numbered list
        if !lessonData.activities.isEmpty {
            let listItems = lessonData.activities.map { ListItem(text: $0, subItems: nil) }
            blocks.append(LessonBlock(
                id: UUID(),
                type: .numberedList,
                data: .numberedList(NumberedListData(items: listItems, startNumber: 1, style: .decimal)),
                order: order
            ))
            order += 1
        }
        
        // Add outcomes as callout
        if !lessonData.outcomes.isEmpty {
            let outcomesText = lessonData.outcomes.joined(separator: "\n• ")
            blocks.append(LessonBlock(
                id: UUID(),
                type: .callout,
                data: .callout(CalloutData(
                    text: "Learning Outcomes:\n• \(outcomesText)",
                    type: .success,
                    title: "What You'll Learn",
                    icon: "target"
                )),
                order: order
            ))
            order += 1
        }
        
        // Create metadata
        let metadata = LessonMetadata(
            difficulty: DifficultyLevel(rawValue: lessonData.contentType.lowercased()) ?? .beginner,
            estimatedDuration: TimeInterval((lessonData.estimatedDuration ?? 30) * 60),
            tags: lessonData.topics,
            prerequisites: [],
            learningObjectives: lessonData.outcomes,
            createdAt: Date(),
            lastModified: Date(),
            version: "1.0",
            language: "en",
            accessibility: AccessibilityInfo(
                hasAltText: true,
                hasTranscripts: false,
                hasSubtitles: false,
                readingLevel: .college,
                colorContrast: .aa
            )
        )
        
        return LessonContent(
            id: UUID(),
            title: lessonData.title,
            description: lessonData.description,
            blocks: blocks,
            metadata: metadata
        )
    }
    
    /// Convert backend course outline to frontend CourseOutline
    func convertToCourseOutline(from response: CourseGenerationResponse) -> CourseOutline? {
        guard let outlineData = response.outline else { return nil }
        
        let lessons = outlineData.lessons.map { lessonData in
            let contentType: LessonContentType
            switch lessonData.contentType.lowercased() {
            case "video": contentType = .video
            case "interactive": contentType = .interactive
            case "quiz": contentType = .quiz
            default: contentType = .text
            }
            
            return LessonOutline(
                title: lessonData.title,
                description: lessonData.description,
                contentType: contentType,
                estimatedDuration: lessonData.estimatedDuration ?? 30
            )
        }
        
        return CourseOutline(
            title: response.title,
            description: response.description,
            lessons: lessons
        )
    }
}
