import Foundation
import Combine
import os.log

// MARK: - Course Request Models
struct CourseGenerationRequest: Codable {
    let topic: String
    let difficulty: String
    let includeProjects: Bool
    let socraticMethod: Bool
    
    enum CodingKeys: String, CodingKey {
        case topic
        case difficulty
        case includeProjects = "include_projects"
        case socraticMethod = "socratic_method"
    }
}

struct AssessmentGenerationRequest: Codable {
    let topic: String
    let questionCount: Int
    let adaptiveDifficulty: Bool
    
    enum CodingKeys: String, CodingKey {
        case topic
        case questionCount = "question_count"
        case adaptiveDifficulty = "adaptive_difficulty"
    }
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

// MARK: - Generic Response Types
struct AIGenerateResponse: Codable {
    let content: String?
    let text: String?
    let detail: String?
    
    var responseText: String {
        return content ?? text ?? detail ?? "No response available"
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

// MARK: - VARK Learning Modalities
enum VARKLearningStyle: String, CaseIterable {
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

// MARK: - Google Gemini Integration
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

// MARK: - AI Avatar API Client
class AIAvatarAPIClient: ObservableObject {
    static let shared = AIAvatarAPIClient()
    
    private let session: URLSession
    private let logger = Logger(subsystem: "com.lyo.app", category: "APIClient")
    
    // Google Gemini API Configuration
    private var geminiAPIKey: String { APIKeys.geminiAPIKey }
    private let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    private var authToken: String? {
        get {
            UserDefaults.standard.string(forKey: "lyo_auth_token")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lyo_auth_token")
        }
    }
    
    // Use APIKeys (which wraps APIEnvironment) for consistency
    private var baseURL: String {
        return APIKeys.baseURL
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        self.session = URLSession(configuration: config)
    }
    
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Codable? = nil
    ) async throws -> T {
        // Normalize base and endpoint to avoid double slashes
        let trimmedBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let trimmedEndpoint = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let fullURLString = "\(trimmedBase)/\(trimmedEndpoint)"
        
        guard let url = URL(string: fullURLString) else {
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
        
        logger.info("🌐 \(method.rawValue) \(url.absoluteString)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
            }
            
            logger.info("📥 Response: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                authToken = nil
                throw APIError.unauthorized
            case 403:
                throw APIError.unauthorized
            case 404:
                throw APIError.invalidResponse
            case 400...499:
                let parsed = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.serverError(httpResponse.statusCode, parsed?.detail ?? parsed?.message)
            case 500...599:
                let parsed = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.serverError(httpResponse.statusCode, parsed?.detail ?? parsed?.message)
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
    
    func getHealth() async throws -> SystemHealthResponse {
        // Align with main backend health route (/health)
        return try await get(endpoint: "health")
    }
    
    // MARK: - Superior AI Backend Integration
    func generateWithSuperiorBackend(_ prompt: String) async throws -> String {
        // First try the deployed Superior AI backend
        do {
            let chatRequest = AvatarMessageRequest(
                message: prompt,
                sessionId: UUID().uuidString,
                mediaUrl: nil
            )
            
            let response: AvatarMessageResponse = try await post(endpoint: "ai/chat", body: chatRequest)
            logger.info("✅ Superior AI Backend response received")
            return response.text
            
        } catch {
            logger.warning("⚠️ Superior AI Backend unavailable, falling back to Gemini")
            return try await generateWithGemini(prompt)
        }
    }
    
    func generateCourseWithBackend(_ topic: String, difficulty: String = "intermediate") async throws -> String {
        do {
            let courseRequest = CourseGenerationRequest(
                topic: topic,
                difficulty: difficulty,
                includeProjects: true,
                socraticMethod: true
            )
            
            let response: AIGenerateResponse = try await post(endpoint: "ai/generate-course", body: courseRequest)
            logger.info("✅ Course generated via Superior AI Backend")
            return response.responseText
            
        } catch {
            logger.warning("⚠️ Course generation unavailable, using enhanced fallback")
            return generateEnhancedCourseContent(topic: topic, difficulty: difficulty)
        }
    }
    
    func createAssessmentWithBackend(_ topic: String, questionCount: Int = 5) async throws -> String {
        do {
            let assessmentRequest = AssessmentGenerationRequest(
                topic: topic,
                questionCount: questionCount,
                adaptiveDifficulty: true
            )
            
            let response: AIGenerateResponse = try await post(endpoint: "ai/create-assessment", body: assessmentRequest)
            logger.info("✅ Assessment created via Superior AI Backend")
            return response.responseText
            
        } catch {
            logger.warning("⚠️ Assessment creation unavailable, using fallback")
            return generateAssessmentFallback(topic: topic, questionCount: questionCount)
        }
    }
    
    private func generateEnhancedCourseContent(topic: String, difficulty: String) -> String {
        return """
        🎓 **\(topic) Course - \(difficulty.capitalized) Level**
        
        **Your Bite-Sized Learning Path:**
        Quick, focused lessons that fit your schedule. Each one is just 3-10 minutes!
        
        **What You'll Learn:**
        🎯 **16 focused lessons** - No fluff, just what matters
        ✨ **Learn by doing** - Interactive exercises from day one
        🚀 **Build real projects** - Apply skills immediately
        � **Track progress** - Celebrate every win
        
        **Learning Style:**
        • Socratic questioning to develop critical thinking
        • Instant practice after each concept
        • Quick wins to keep you motivated
        • Build confidence step by step
        
        **Projects You'll Build:**
        🛠️ Mini-projects in every lesson
        📱 Complete application by the end
        🔄 Real-world practice exercises
        
        Ready to start? Let's dive into your first bite-sized lesson! 🚀
        """
    }
    
    private func generateAssessmentFallback(topic: String, questionCount: Int) -> String {
        return """
        🧠 **\(topic) Knowledge Assessment**
        
        I'll create an adaptive assessment with \(questionCount) questions to evaluate your understanding of \(topic).
        
        **Assessment Features:**
        • Adaptive difficulty based on your responses
        • Immediate feedback with explanations
        • Personalized learning recommendations
        • Progress tracking and analytics
        
        **Question Types:**
        📝 Conceptual understanding
        🔍 Problem-solving scenarios  
        💻 Code analysis and debugging
        🎯 Practical application questions
        
        Ready to test your knowledge? Let's start with the first question about \(topic) fundamentals!
        """
    }
    
    // MARK: - Google Gemini Integration (Fallback)
    func generateWithGemini(_ prompt: String) async throws -> String {
        // Check if API key is configured
        guard APIKeys.isGeminiAPIKeyConfigured else {
            logger.warning("⚠️ Gemini API key not configured - using advanced fallback")
            return generateAdvancedFallbackResponse(for: prompt)
        }
        
        guard let url = URL(string: "\(geminiBaseURL)?key=\(geminiAPIKey)") else {
            throw APIError.invalidURL
        }
        
        // Use the prompt as-is - it's already formatted by the caller
        let geminiRequest = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: prompt)
                    ]
                )
            ]
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(geminiRequest)
        } catch {
            logger.error("❌ Failed to encode Gemini request: \(error)")
            throw APIError.decodingError(error)
        }
        
        logger.info("🤖 Sending request to Google Gemini")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
            }
            
            logger.info("📥 Gemini Response: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.error("❌ Gemini API Error: \(errorText)")
                throw APIError.serverError(httpResponse.statusCode, errorText)
            }
            
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            guard let firstCandidate = geminiResponse.candidates.first,
                  let firstPart = firstCandidate.content.parts.first else {
                throw APIError.noData
            }
            
            logger.info("✅ Gemini response received successfully")
            return firstPart.text
            
        } catch let error as APIError {
            throw error
        } catch {
            logger.error("❌ Gemini network error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    private func generateAdvancedFallbackResponse(for prompt: String) -> String {
        let input = prompt.lowercased()
        
        // Socratic teaching fallback responses
        if input.contains("course") || input.contains("learn") {
            return """
            🤔 **Let's explore this together!** What specific aspect of learning interests you most?
            
            Before I create a personalized course, I'd love to understand:
            • What's your current experience level?
            • What learning style works best for you?
            • What's your ultimate goal with this knowledge?
            
            **Available Learning Paths:**
            🎯 **Guided Discovery Track** - Socratic questioning approach
            🛠️ **Hands-on Building Track** - Project-based learning
            🧠 **Conceptual Mastery Track** - Theory with practical application
            📚 **Self-Paced Study Track** - Flexible timeline learning
            
            Which approach resonates with you? Or would you prefer a hybrid approach combining multiple methods?
            """
        }
        
        if input.contains("swift") || input.contains("ios") {
            return """
            🍎 **iOS Development Journey** - Let's think critically about this!
            
            Before diving into Swift, let me ask: *What problem are you hoping to solve by building iOS apps?*
            
            **Socratic Exploration:**
            🤔 What makes a great mobile app from a user's perspective?
            🔍 How do you think iOS apps differ fundamentally from web applications?
            💡 What's one iOS app you admire, and what makes it special?
            
            **Learning Path Preview:**
            **Week 1-2:** Swift Fundamentals + Critical Thinking
            • *Why* does Swift use optionals? Let's discover together
            • *How* does type safety prevent common errors?
            
            **Week 3-4:** SwiftUI + Design Thinking  
            • *What* makes interfaces intuitive?
            • *When* should we use different UI components?
            
            Your answers will shape our learning journey. What draws you to iOS development?
            """
        }
        
        // Default socratic response
        return """
        🌟 **Excellent question!** Let's explore this together using the Socratic method.
        
        Instead of giving you a direct answer, let me guide you to discover it yourself:
        
        🤔 **Think about this:** What do you already know about this topic?
        🔍 **Consider:** What assumptions might you be making?
        💡 **Reflect:** What would happen if we approached this differently?
        
        **My teaching approach:**
        • Questions that lead to insights
        • Building knowledge through discovery
        • Connecting concepts to real-world applications
        • Encouraging critical thinking over memorization
        
        Now, based on your current understanding, how would *you* approach this problem? I'll guide you from there!
        """
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
                print("✅ Backend health check passed: \(health.status)")
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
        // Create a default context since the backend doesn't have avatar context endpoints yet
        let defaultContext = AvatarContextResponse(
            topicsCovered: ["iOS Development", "SwiftUI", "Learning"],
            learningGoals: ["Master iOS Development", "Build Great Apps"],
            currentModule: "iOS Fundamentals",
            engagementLevel: 0.8,
            lastInteraction: Date().timeIntervalSince1970
        )
        
        await MainActor.run {
            self.currentContext = defaultContext
            self.isConnected = true
            self.isLoading = false
            self.logger.info("✅ Default avatar context loaded (backend context not available)")
        }
    }
    
    func updateAvatarContext(request: AvatarContextRequest) async {
        // Update the local context with the requested changes since backend doesn't support this yet
        if let currentContext = currentContext {
            let updatedContext = AvatarContextResponse(
                topicsCovered: request.topics ?? currentContext.topicsCovered,
                learningGoals: request.learningGoals ?? currentContext.learningGoals,
                currentModule: request.currentModule ?? currentContext.currentModule,
                engagementLevel: currentContext.engagementLevel,
                lastInteraction: Date().timeIntervalSince1970
            )
            
            await MainActor.run {
                self.currentContext = updatedContext
                self.isLoading = false
                self.logger.info("✅ Avatar context updated locally (backend update not available)")
            }
        } else {
            // If no current context, load default
            await loadAvatarContext()
        }
    }
    
    func sendMessage(_ text: String, mediaUrl: String? = nil) async -> AIChatMessage? {
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
        
        // Try Google Gemini API for real AI responses
        
        do {
            // Try Superior Backend first, then fallback to Gemini
            let responseText = try await apiClient.generateWithSuperiorBackend(text)
            
            // Check if user is asking for course creation
            if text.lowercased().contains("course") || text.lowercased().contains("create") {
                let courseContent = try await apiClient.generateCourseWithBackend(text)
                let finalResponse = "\(responseText)\n\n\(courseContent)"
                
                let avatarMessage = AIChatMessage(
                    id: UUID().uuidString,
                    text: finalResponse,
                    isFromUser: false,
                    timestamp: Date(),
                    detectedTopics: detectTopics(in: text),
                    includeReactionButtons: true,
                    suggestAdvancedContent: true
                )
                
                await MainActor.run {
                    self.messages.append(avatarMessage)
                    self.isTyping = false
                    self.logger.info("✅ Course creation response sent")
                }
                
                return avatarMessage
            }
            
            // Check if user wants an assessment/quiz
            if text.lowercased().contains("quiz") || text.lowercased().contains("test") || text.lowercased().contains("assessment") {
                let assessmentContent = try await apiClient.createAssessmentWithBackend(text)
                let finalResponse = "\(responseText)\n\n\(assessmentContent)"
                
                let avatarMessage = AIChatMessage(
                    id: UUID().uuidString,
                    text: finalResponse,
                    isFromUser: false,
                    timestamp: Date(),
                    detectedTopics: detectTopics(in: text),
                    includeReactionButtons: true,
                    suggestAdvancedContent: false
                )
                
                await MainActor.run {
                    self.messages.append(avatarMessage)
                    self.isTyping = false
                    self.logger.info("✅ Assessment response sent")
                }
                
                return avatarMessage
            }
            
            let avatarMessage = AIChatMessage(
                id: UUID().uuidString,
                text: responseText,
                isFromUser: false,
                timestamp: Date(),
                detectedTopics: detectTopics(in: text),
                includeReactionButtons: false,
                suggestAdvancedContent: text.lowercased().contains("advanced") || text.lowercased().contains("expert")
            )
            
            await MainActor.run {
                self.messages.append(avatarMessage)
                self.isTyping = false
                self.logger.info("✅ Message sent and response received")
            }
            
            return avatarMessage
            
        } catch {
            // Provide intelligent fallback response based on user input
            self.logger.error("❌ Gemini API failed, using fallback: \(error)")
            
            let fallbackMessage = AIChatMessage(
                id: UUID().uuidString,
                text: generateSmartResponse(for: text),
                isFromUser: false,
                timestamp: Date(),
                detectedTopics: detectTopics(in: text),
                includeReactionButtons: false,
                suggestAdvancedContent: false
            )
            
            await MainActor.run {
                self.messages.append(fallbackMessage)
                self.isTyping = false
                self.lastError = error
                self.logger.info("🤖 Providing smart fallback response")
            }
            
            return fallbackMessage
        }
    }
    
    // Smart response generation for socratic learning and course creation
    private func generateSmartResponse(for userInput: String) -> String {
        let input = userInput.lowercased()
        
        // Socratic approach for beginners
        if input.contains("new to programming") || input.contains("beginner") || input.contains("start learning") {
            return """
            🤔 **Welcome to your learning journey!** Before we begin, let me ask you some guiding questions:
            
            **Let's discover together:**
            • What sparked your interest in programming? 
            • What problems do you hope to solve with code?
            • How do you learn best - by doing, reading, or discussing?
            
            **Socratic Learning Paths Available:**
            🎯 **Discovery-Based Programming** - Questions lead to understanding
            📱 **iOS Development Through Inquiry** - Build apps while exploring why
            🧠 **Critical Thinking + Code** - Philosophy meets programming
            
            **My approach with beginners:**
            Instead of "Here's how variables work," I ask: *"What do you think a program needs to remember things?"*
            Instead of "This is a loop," I wonder: *"How might we tell a computer to repeat something?"*
            
            What question about programming are you most curious about right now?
            """
        }
        
        if input.contains("course") || input.contains("study plan") || input.contains("learning path") {
            return """
            🎓 **Let's design your perfect learning experience!** But first, some Socratic exploration:
            
            🤔 **Before I create your course, let's think:**
            • What does "mastery" mean to you in this field?
            • How do you know when you've truly learned something?
            • What's the difference between memorizing and understanding?
            
            **Socratic Course Options:**
            📱 **iOS Development Through Questions**
            • *Why* does iOS work the way it does?
            • *How* can we think like Apple designers?
            • *What* makes great user experiences?
            
            🧠 **Full Stack Philosophy & Practice**  
            • *What* problems does each technology solve?
            • *Why* do we separate frontend and backend?
            • *How* do systems think and communicate?
            
            🤖 **AI Through Critical Thinking**
            • *What* is intelligence, really?
            • *How* can machines "learn"?
            • *Why* does this matter for humanity?
            
            **My Socratic Method:**
            Instead of "Here's how to code," I ask: *"What do you think this code is trying to accomplish?"*
            Instead of "Memorize this pattern," we explore: *"When might this approach fail? What would you do instead?"*
            
            What field calls to your curiosity? What questions keep you up at night?
            """
        }
        
        if input.contains("swift") || input.contains("ios") {
            return """
            🍎 **iOS Development Through Socratic Inquiry**
            
            Before we dive into syntax, let's explore the deeper questions:
            
            🤔 **Fundamental Questions:**
            • *Why* did Apple create Swift instead of just using Objective-C?
            • *What* makes a mobile app feel "native" vs "web-like"?
            • *How* do you think touch interfaces change how we design?
            
            **Socratic Learning Journey:**
            
            **Week 1-2: Swift Philosophy & Fundamentals**
            • Instead of "Here's how optionals work," we ask: *"What happens when data doesn't exist? How should we handle uncertainty?"*
            • Rather than memorizing syntax: *"Why might Swift choose this way of writing code? What problems does it solve?"*
            
            **Week 3-4: SwiftUI & Interface Thinking**
            • Not just "Use VStack for vertical layouts," but: *"How do you think about organizing information spatially?"*
            • Beyond tutorials: *"What makes some apps feel intuitive while others feel confusing?"*
            
            **Week 5-6: Systems Thinking**
            • More than "Here's how to save data," we explore: *"How should an app remember things? What are the tradeoffs?"*
            • Beyond API calls: *"How do apps communicate with the world? What can go wrong, and how do we prepare?"*
            
            **The Socratic Project:**
            Instead of following a tutorial, we'll build an app by asking: *"What problem do you want to solve? How might we approach it? What would users really need?"*
            
            What aspect of iOS development makes you most curious?
            """
        }
        
        if input.contains("help") || input.contains("what") || input.contains("how") {
            return """
            🤔 **Great question!** Instead of just listing what I can do, let me ask: *What kind of learning experience are you hoping for?*
            
            **My Socratic Teaching Philosophy:**
            🎯 **Questions over Answers** - I guide you to discover insights yourself
            🧠 **Critical Thinking First** - We explore the "why" before the "how"  
            💡 **Personalized Inquiry** - Your curiosity shapes our journey
            🔄 **Learning Through Dialogue** - Conversation leads to understanding
            
            **What makes me different:**
            Instead of: *"Here's how variables work"*
            I ask: *"What do you think a program needs to remember things?"*
            
            Instead of: *"Follow this tutorial"*  
            I wonder: *"What problem are you trying to solve? How might we approach it?"*
            
            **I excel at:**
            📚 **Socratic Course Design** - Learning through guided questions
            🎯 **Adaptive Teaching** - Methods that match your thinking style
            💻 **Philosophy + Practice** - Deep understanding meets practical skills
            🚀 **Critical Thinking Development** - Building meta-learning abilities
            
            So... what's sparking your curiosity today? What questions are you wrestling with?
            """
        }
        
        // Default socratic encouraging response
        return """
        🌟 **Fascinating!** You've touched on something really interesting here.
        
        Rather than giving you a quick answer, let's explore this together using the Socratic method:
        
        🤔 **Let's start here:** What do you already know or suspect about this topic?
        🔍 **Think deeper:** What assumptions might we be making?
        💡 **Consider this:** What would happen if we approached this from a completely different angle?
        
        **My teaching philosophy:**
        • Every great answer starts with better questions
        • Understanding comes from discovery, not memorization  
        • Your curiosity is the best curriculum
        • Mistakes are insights waiting to be uncovered
        
        **I specialize in:**
        🎯 Socratic programming education
        📚 Question-driven course creation
        🧠 Critical thinking development
        💻 Philosophy meets practical coding
        
        Now, what aspect of this topic makes you most curious? Let's explore it together!
        """
    }
    
    // Detect topics in user input for better context
    private func detectTopics(in text: String) -> [String] {
        let input = text.lowercased()
        var topics: [String] = []
        
        if input.contains("swift") || input.contains("ios") { topics.append("iOS Development") }
        if input.contains("programming") || input.contains("code") { topics.append("Programming") }
        if input.contains("course") || input.contains("learn") { topics.append("Course Creation") }
        if input.contains("beginner") || input.contains("new") { topics.append("Beginner") }
        if input.contains("advanced") { topics.append("Advanced") }
        if input.contains("web") || input.contains("html") || input.contains("css") { topics.append("Web Development") }
        if input.contains("data") || input.contains("ml") || input.contains("ai") { topics.append("Data Science") }
        
        return topics
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
            let _: SystemHealthResponse = try await apiClient.get(endpoint: "health")
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
        // Use the real backend authentication, then propagate the token to the avatar client
        do {
            let loginResponse = try await APIClient.shared.login(email: email, password: password)
            // Set the same access token for the avatar API client
            AIAvatarAPIClient.shared.setAuthToken(loginResponse.actualAccessToken)
            
            await MainActor.run {
                self.isConnected = true
                self.logger.info("✅ Authentication successful for \(email)")
            }
            
            await loadAvatarContext()
            return true
        } catch {
            await MainActor.run {
                self.isConnected = false
                self.lastError = error
                self.logger.error("❌ Authentication failed: \(error.localizedDescription)")
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
