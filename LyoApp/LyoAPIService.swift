import Foundation
import Combine

/// API service for Lyo AI Learn Buddy backend integration
@MainActor
class LyoAPIService: ObservableObject {
    static let shared = LyoAPIService()
    
    // MARK: - Configuration
    private let baseURL = LyoConfiguration.getBackendURL()
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    @Published var isConnected = false
    @Published var lastError: APIError?
    @Published var isLoading = false
    
    // MARK: - Authentication
    private var authToken: String?
    private var currentUserId: Int?
    
    private init() {
        checkConnection()
    }
    
    // MARK: - Connection Management
    
    func checkConnection() {
        guard let url = URL(string: "\(baseURL)/ai/health") else { return }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    self?.isConnected = true
                    self?.lastError = nil
                } else {
                    self?.isConnected = false
                    self?.lastError = .connectionError
                }
            }
        }.resume()
    }
    
    func setAuthToken(_ token: String, userId: Int) {
        authToken = token
        currentUserId = userId
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
            endpoint: "/ai/curriculum/course-outline",
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
            endpoint: "/ai/mentor/conversation",
            method: .POST,
            body: request,
            responseType: MentorResponse.self
        )
    }
    
    /// Get conversation history with mentor
    func getConversationHistory(limit: Int = 20) async throws -> ConversationHistoryResponse {
        let endpoint = "/ai/mentor/history?limit=\(limit)"
        
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
            endpoint: "/ai/curriculum/lesson-content",
            method: .POST,
            body: request,
            responseType: LessonContentResponse.self
        )
    }
    
    /// Get AI system health status
    func getSystemHealth() async throws -> AIHealthResponse {
        return try await performRequest(
            endpoint: "/ai/health",
            method: .GET,
            body: nil as EmptyRequest?,
            responseType: AIHealthResponse.self
        )
    }
    
    /// Rate an interaction
    func rateInteraction(interactionId: String, wasHelpful: Bool) async throws {
        let request = InteractionRatingRequest(
            interactionId: interactionId,
            wasHelpful: wasHelpful
        )
        
        let _: EmptyResponse = try await performRequest(
            endpoint: "/ai/mentor/rate",
            method: .POST,
            body: request,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Generic Request Handler
    
    private func performRequest<T: Codable, R: Codable>(
        endpoint: String,
        method: HTTPMethod,
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
                throw APIError.encodingError
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
                throw APIError.invalidResponse
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
                    throw APIError.decodingError
                }
                
            case 400:
                throw APIError.badRequest
            case 401:
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 500...599:
                throw APIError.serverError
            default:
                throw APIError.unknownError
            }
            
        } catch {
            isLoading = false
            if let apiError = error as? APIError {
                lastError = apiError
                throw apiError
            } else {
                lastError = .networkError
                throw APIError.networkError
            }
        }
    }
}

// MARK: - HTTP Method Enum

// HTTPMethod is defined in NetworkLayer.swift

// MARK: - API Error Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case decodingError
    case networkError
    case connectionError
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error occurred"
        case .connectionError:
            return "Cannot connect to server"
        case .invalidResponse:
            return "Invalid response from server"
        case .badRequest:
            return "Bad request"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}

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

struct EmptyResponse: Codable {
    // Empty response for endpoints that return no data
}

// MARK: - API Service Extensions

extension LyoAPIService {
    /// Convert backend lesson data to frontend LessonContent
    func convertToLessonContent(from lessonData: LessonData) -> LessonContent {
        var blocks: [LessonBlock] = []
        var order = 0
        
        // Add title as heading
        blocks.append(LessonBlock(
            type: .heading,
            data: .heading(HeadingData(text: lessonData.title, level: 1, style: .normal)),
            order: order
        ))
        order += 1
        
        // Add description as paragraph
        blocks.append(LessonBlock(
            type: .paragraph,
            data: .paragraph(ParagraphData(text: lessonData.description, style: .normal)),
            order: order
        ))
        order += 1
        
        // Add topics as bullet list
        if !lessonData.topics.isEmpty {
            let listItems = lessonData.topics.map { ListItem(text: $0, subItems: nil) }
            blocks.append(LessonBlock(
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