import Foundation
import Combine
import os.log

// MARK: - API Configuration
struct APIConfig {
    static let developmentURL = "http://localhost:8000/api/v1"
    static let baseURL = developmentURL
    static let requestTimeout: TimeInterval = 30.0
    static let webSocketURL = "ws://localhost:8000/api/v1/ws"
}

struct DevelopmentConfig {
    static let useMockData = false
    static let enableDebugLogging = true
    // Authentication credentials should come from user input or secure storage
    // not hardcoded for security reasons
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(Int, String?)
    case unauthorized
    case forbidden
    case notFound
    case timeout
    case unknown(Error)
    
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
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .timeout:
            return "Request timed out"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - HTTP Methods
// HTTPMethod is defined in NetworkLayer.swift to avoid duplication

// MARK: - Response Models
struct ErrorResponse: Codable {
    let detail: String
}

struct HealthResponse: Codable {
    let status: String
    let message: String
    let timestamp: String
}

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

// MARK: - AI Avatar Request Models
struct AvatarMessageRequest: Codable {
    let message: String
    let sessionId: String?
    let mediaUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case sessionId = "session_id"
        case mediaUrl = "media_url"
    }
}

struct AvatarContextRequest: Codable {
    let topics: [String]?
    let learningGoals: [String]?
    let currentModule: String?
    let persona: String?
    let learningStyle: String?
    let learningPace: String?
    let strengths: [String]?
    let areasForImprovement: [String]?
    let preferredResources: [String]?
    
    enum CodingKeys: String, CodingKey {
        case topics
        case learningGoals = "learning_goals"
        case currentModule = "current_module"
        case persona
        case learningStyle = "learning_style"
        case learningPace = "learning_pace"
        case strengths
        case areasForImprovement = "areas_for_improvement"
        case preferredResources = "preferred_resources"
    }
}

// MARK: - AI Avatar Response Models
struct AvatarMessageResponse: Codable {
    let text: String
    let timestamp: Double
    let detectedTopics: [String]?
    let moderated: Bool?
    let includeReactionButtons: Bool?
    let suggestAdvancedContent: Bool?
    
    enum CodingKeys: String, CodingKey {
        case text, timestamp
        case detectedTopics = "detected_topics"
        case moderated
        case includeReactionButtons = "include_reaction_buttons"
        case suggestAdvancedContent = "suggest_advanced_content"
    }
}

struct AvatarContextResponse: Codable {
    let topicsCovered: [String]
    let learningGoals: [String]
    let currentModule: String?
    let engagementLevel: Double
    let lastInteraction: Double
    
    enum CodingKeys: String, CodingKey {
        case topicsCovered = "topics_covered"
        case learningGoals = "learning_goals"
        case currentModule = "current_module"
        case engagementLevel = "engagement_level"
        case lastInteraction = "last_interaction"
    }
}

// MARK: - AI Avatar Personas
enum AvatarPersona: String, CaseIterable {
    case friendly = "friendly"
    case professional = "professional"
    case encouraging = "encouraging"
    case playful = "playful"
    case scholarly = "scholarly"
    
    var displayName: String {
        switch self {
        case .friendly: return "Friendly"
        case .professional: return "Professional"
        case .encouraging: return "Encouraging"
        case .playful: return "Playful"
        case .scholarly: return "Scholarly"
        }
    }
    
    var description: String {
        switch self {
        case .friendly: return "Warm and approachable teaching style"
        case .professional: return "Formal and structured learning approach"
        case .encouraging: return "Motivating and supportive guidance"
        case .playful: return "Fun and engaging learning experience"
        case .scholarly: return "Academic and research-focused approach"
        }
    }
}

// MARK: - Learning Styles
enum LearningStyle: String, CaseIterable {
    case visual = "visual"
    case auditory = "auditory"
    case kinesthetic = "kinesthetic"
    case reading = "reading"
    case multimodal = "multimodal"
    
    var displayName: String {
        switch self {
        case .visual: return "Visual"
        case .auditory: return "Auditory"
        case .kinesthetic: return "Kinesthetic"
        case .reading: return "Reading/Writing"
        case .multimodal: return "Multimodal"
        }
    }
    
    var description: String {
        switch self {
        case .visual: return "Learn best through images, diagrams, and visual aids"
        case .auditory: return "Learn best through listening and discussion"
        case .kinesthetic: return "Learn best through hands-on activities and movement"
        case .reading: return "Learn best through reading and writing"
        case .multimodal: return "Learn best through multiple approaches"
        }
    }
}

// MARK: - AI Chat Message Model
struct AIChatMessage: Identifiable {
    let id: String
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    let mediaUrl: String?
    let detectedTopics: [String]?
    let includeReactionButtons: Bool?
    let suggestAdvancedContent: Bool?
    
    init(id: String, text: String, isFromUser: Bool, timestamp: Date, mediaUrl: String? = nil, detectedTopics: [String]? = nil, includeReactionButtons: Bool? = nil, suggestAdvancedContent: Bool? = nil) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.mediaUrl = mediaUrl
        self.detectedTopics = detectedTopics
        self.includeReactionButtons = includeReactionButtons
        self.suggestAdvancedContent = suggestAdvancedContent
    }
}

// MARK: - AI Avatar API Client
class AIAvatarAPIClient: ObservableObject {
    static let shared = AIAvatarAPIClient()
    
    private let session: URLSession
    private let logger = Logger(subsystem: "com.lyo.app", category: "APIClient")
    
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
        self.session = URLSession(configuration: config)
    }
    
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
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.decodingError(error)
            }
        }
        
        if DevelopmentConfig.enableDebugLogging {
            logger.info("🌐 \(method.rawValue) \(url.absoluteString)")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
            }
            
            if DevelopmentConfig.enableDebugLogging {
                logger.info("📥 Response: \(httpResponse.statusCode)")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
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
    
    func get<T: Codable>(endpoint: String) async throws -> T {
        return try await request(endpoint: endpoint, method: .GET)
    }
    
    func post<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T {
        return try await request(endpoint: endpoint, method: .POST, body: body)
    }
    
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
    
    func getHealth() async throws -> HealthResponse {
        return try await get(endpoint: "health")
    }
}

// MARK: - AI Avatar Service
@MainActor
class AIAvatarService: ObservableObject {
    static let shared = AIAvatarService()
    
    private let apiClient = AIAvatarAPIClient.shared
    private let logger = Logger(subsystem: "com.lyo.app", category: "AIAvatarService")
    
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var currentContext: AvatarContextResponse?
    @Published var lastError: Error?
    @Published var messages: [AIChatMessage] = []
    @Published var isTyping = false
    
    private var currentSessionId: String?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupConnectionMonitoring()
    }
    
    private func setupConnectionMonitoring() {
        NotificationCenter.default.publisher(for: .authenticationStateChanged)
            .sink { [weak self] _ in
                self?.handleAuthenticationChange()
            }
            .store(in: &cancellables)
            
        // Check connection status on initialization
        Task {
            await checkBackendConnection()
        }
    }
    
    private func checkBackendConnection() async {
        do {
            // Try to connect to backend health endpoint
            let health = try await apiClient.getHealth()
            await MainActor.run {
                self.isConnected = true
                print("✅ Backend health check passed: \(health.status) - \(health.message)")
                self.loadAvatarContextIfAuthenticated()
            }
        } catch {
            await MainActor.run {
                self.isConnected = false
                self.lastError = error
                print("⚠️ Backend connection failed: \(error)")
            }
        }
    }
    
    private func loadAvatarContextIfAuthenticated() {
        if apiClient.hasAuthToken() {
            Task {
                await loadAvatarContext()
            }
        }
    }
    
    private func handleAuthenticationChange() {
        if apiClient.hasAuthToken() {
            Task {
                await loadAvatarContext()
            }
        } else {
            currentContext = nil
            isConnected = false
        }
    }
    
    func loadAvatarContext() async {
        guard apiClient.hasAuthToken() else {
            logger.warning("No auth token available for loading avatar context")
            return
        }
        
        isLoading = true
        lastError = nil
        
        do {
            let context: AvatarContextResponse = try await apiClient.get(endpoint: "ai/avatar/context")
            
            await MainActor.run {
                self.currentContext = context
                self.isConnected = true
                self.isLoading = false
                self.logger.info("✅ Avatar context loaded successfully")
            }
        } catch {
            await MainActor.run {
                self.lastError = error
                self.isLoading = false
                self.logger.error("❌ Failed to load avatar context: \(error.localizedDescription)")
            }
        }
    }
    
    func updateAvatarContext(request: AvatarContextRequest) async {
        guard apiClient.hasAuthToken() else {
            logger.warning("No auth token available for updating avatar context")
            return
        }
        
        isLoading = true
        lastError = nil
        
        do {
            let context: AvatarContextResponse = try await apiClient.post(
                endpoint: "ai/avatar/context",
                body: request
            )
            
            await MainActor.run {
                self.currentContext = context
                self.isLoading = false
                self.logger.info("✅ Avatar context updated successfully")
            }
        } catch {
            await MainActor.run {
                self.lastError = error
                self.isLoading = false
                self.logger.error("❌ Failed to update avatar context: \(error.localizedDescription)")
            }
        }
    }
    
    func sendMessage(_ text: String, mediaUrl: String? = nil) async -> AIChatMessage? {
        guard apiClient.hasAuthToken() else {
            logger.warning("No auth token available for sending message")
            return nil
        }
        
        let userMessage = AIChatMessage(
            id: UUID().uuidString,
            text: text,
            isFromUser: true,
            timestamp: Date(),
            mediaUrl: mediaUrl
        )
        
        messages.append(userMessage)
        isTyping = true
        lastError = nil
        
        let request = AvatarMessageRequest(
            message: text,
            sessionId: currentSessionId,
            mediaUrl: mediaUrl
        )
        
        do {
            let response: AvatarMessageResponse = try await apiClient.post(
                endpoint: "ai/avatar/message",
                body: request
            )
            
            let avatarMessage = AIChatMessage(
                id: UUID().uuidString,
                text: response.text,
                isFromUser: false,
                timestamp: Date(timeIntervalSince1970: response.timestamp),
                detectedTopics: response.detectedTopics,
                includeReactionButtons: response.includeReactionButtons,
                suggestAdvancedContent: response.suggestAdvancedContent
            )
            
            await MainActor.run {
                self.messages.append(avatarMessage)
                self.isTyping = false
                self.logger.info("✅ Message sent and response received")
            }
            
            return avatarMessage
            
        } catch {
            await MainActor.run {
                self.isTyping = false
                self.lastError = error
                self.logger.error("❌ Failed to send message: \(error.localizedDescription)")
            }
            
            return nil
        }
    }
    
    func startNewSession() {
        currentSessionId = UUID().uuidString
        messages.removeAll()
        logger.info("🆕 New avatar session started: \(self.currentSessionId ?? "unknown")")
    }
    
    func endSession() {
        messages = []
        currentSessionId = nil
    }
    
    func checkBackendHealth() async -> Bool {
        do {
            let _: HealthResponse = try await apiClient.get(endpoint: "health")
            await MainActor.run {
                self.isConnected = true
                self.logger.info("✅ Backend health check passed")
            }
            return true
        } catch {
            await MainActor.run {
                self.isConnected = false
                self.logger.error("❌ Backend health check failed: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    func authenticateWithUserCredentials(email: String, password: String) async -> Bool {
        let loginRequest = LoginRequest(
            email: email,
            password: password
        )
        
        do {
            let response: LoginResponse = try await apiClient.post(
                endpoint: "auth/login",
                body: loginRequest
            )
            
            apiClient.setAuthToken(response.token)
            
            await MainActor.run {
                self.isConnected = true
                self.logger.info("✅ Authentication successful for \(email)")
            }
            
            await loadAvatarContext()
            
            return true
            
        } catch {
            await MainActor.run {
                self.lastError = error
                self.logger.error("❌ Authentication failed for \(email): \(error.localizedDescription)")
            }
            
            return false
        }
    }
    
    func hasValidAuthToken() -> Bool {
        return apiClient.hasAuthToken()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let authenticationStateChanged = Notification.Name("authenticationStateChanged")
}