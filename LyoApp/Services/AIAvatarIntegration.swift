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
