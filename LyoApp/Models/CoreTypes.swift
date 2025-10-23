//
//  CoreTypes.swift
//  LyoApp
//
//  Consolidated core type definitions to ensure compilation visibility
//  All base types that are used across multiple files are defined here
//  This file has no dependencies on other project files, ensuring it compiles first
//
//  Created: October 20, 2025
//

import Foundation
import SwiftUI

// MARK: - ============================================================
// MARK: - AI MESSAGE (Chat & Conversation)
// MARK: - ============================================================

/// Standard chat message structure used across all chat interfaces
/// This is the single source of truth for all chat/AI message types
public struct AIMessage: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let content: String
    public let isFromUser: Bool
    public let timestamp: Date
    public let messageType: MessageType
    public let interactionId: Int?
    
    // MARK: - Message Type
    public enum MessageType: String, Codable {
        case text
        case code
        case explanation
        case quiz
        case resource
        case system
    }
    
    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        messageType: MessageType = .text,
        interactionId: Int? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.messageType = messageType
        self.interactionId = interactionId
    }
}

/// Type alias for backward compatibility
public typealias ChatMessage = AIMessage

// MARK: - ============================================================
// MARK: - LEARNING BLUEPRINT (AI Onboarding)
// MARK: - ============================================================

/// Represents a learning blueprint structure generated during AI onboarding
public struct LearningBlueprint: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let nodes: [BlueprintNode]
    public let connectionPath: [String]
    public let createdAt: Date
    public let completionPercentage: Double
    
    // Properties used by Avatar.fromDiagnostic
    public var learningGoals: String
    public var preferredStyle: String
    public var timeline: Int?  // Days to complete
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        nodes: [BlueprintNode] = [],
        connectionPath: [String] = [],
        createdAt: Date = Date(),
        completionPercentage: Double = 0.0,
        learningGoals: String = "",
        preferredStyle: String = "",
        timeline: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.nodes = nodes
        self.connectionPath = connectionPath
        self.createdAt = createdAt
        self.completionPercentage = completionPercentage
        self.learningGoals = learningGoals
        self.preferredStyle = preferredStyle
        self.timeline = timeline
    }
}

/// Represents a single node in a learning blueprint
public struct BlueprintNode: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let topic: String
    public let type: BlueprintNodeType
    public let description: String
    public let position: CGPoint
    public let isCompleted: Bool
    public let dependencies: [UUID]
    public let estimatedTime: TimeInterval
    
    public init(
        id: UUID = UUID(),
        title: String,
        topic: String,
        type: BlueprintNodeType = .lesson,
        description: String = "",
        position: CGPoint = .zero,
        isCompleted: Bool = false,
        dependencies: [UUID] = [],
        estimatedTime: TimeInterval = 300
    ) {
        self.id = id
        self.title = title
        self.topic = topic
        self.type = type
        self.description = description
        self.position = position
        self.isCompleted = isCompleted
        self.dependencies = dependencies
        self.estimatedTime = estimatedTime
    }
}

public enum BlueprintNodeType: String, Codable {
    case lesson, quiz, practice, project, review, assessment
}

// MARK: - ============================================================
// MARK: - AVATAR SYSTEM (Core Types)
// MARK: - ============================================================

// MARK: - Avatar Style

/// Visual style/appearance base for avatars
public enum AvatarStyle: String, Codable, CaseIterable, Identifiable {
    case friendlyBot = "Friendly Bot"
    case wiseMentor = "Wise Mentor"
    case energeticCoach = "Energetic Coach"
    
    public var id: String { rawValue }
    
    public var emoji: String {
        switch self {
        case .friendlyBot: return "🤖"
        case .wiseMentor: return "🧙‍♂️"
        case .energeticCoach: return "🦁"
        }
    }
    
    public var gradientColors: [Color] {
        switch self {
        case .friendlyBot: return [.blue.opacity(0.7), .cyan.opacity(0.5)]
        case .wiseMentor: return [.purple.opacity(0.7), .indigo.opacity(0.5)]
        case .energeticCoach: return [.orange.opacity(0.7), .yellow.opacity(0.5)]
        }
    }
    
    public var description: String {
        switch self {
        case .friendlyBot: return "Curious & approachable"
        case .wiseMentor: return "Patient & thoughtful"
        case .energeticCoach: return "Motivating & dynamic"
        }
    }
}

// MARK: - Personality

/// Core personality type determining avatar behavior and interaction style
public enum Personality: String, Codable, CaseIterable, Identifiable {
    case friendlyCurious = "Lyo"
    case energeticCoach = "Max"
    case calmReflective = "Luna"
    case wisePatient = "Sage"
    
    public var id: String { rawValue }
    
    public var systemPrompt: String {
        switch self {
        case .friendlyCurious:
            return """
            You are Lyo, a warm and curious learning companion. Your approach:
            - Ask questions first to understand the learner's perspective
            - Explain concepts simply with relatable examples
            - Show genuine excitement about discoveries
            - Use encouraging language: "Great question!", "Let's explore that together"
            - Keep responses conversational and under 120 words unless detail is requested
            """
        case .energeticCoach:
            return """
            You are Max, a high-energy motivational coach. Your approach:
            - Set clear goals and celebrate every win
            - Push learners gently beyond their comfort zone
            - Use action-oriented language: "Let's tackle this!", "You've got this!"
            - Track progress explicitly and highlight improvements
            - Keep energy high but sensitive to frustration
            """
        case .calmReflective:
            return """
            You are Luna, a calm and reflective guide. Your approach:
            - Slow the pace and create space for deep thinking
            - Use reflection prompts: "What do you notice?", "How does that feel?"
            - Embrace silence and processing time
            - Connect concepts to bigger themes mindfully
            - Speak in a gentle, reassuring tone
            """
        case .wisePatient:
            return """
            You are Sage, a patient Socratic tutor. Your approach:
            - Guide with questions rather than direct answers
            - Break complex problems into small, manageable steps
            - Connect new concepts to existing knowledge
            - Never rush; let understanding develop naturally
            - Use wisdom sayings and analogies to illuminate concepts
            """
        }
    }
    
    public var tagline: String {
        switch self {
        case .friendlyCurious: return "Warm, curious mentor who asks questions first"
        case .energeticCoach: return "High-energy coach who celebrates your wins"
        case .calmReflective: return "Calm guide who creates space for reflection"
        case .wisePatient: return "Patient tutor who connects concepts deeply"
        }
    }
    
    public var sampleGreeting: String {
        switch self {
        case .friendlyCurious: return "Hi! I'm Lyo. Let's explore and learn together!"
        case .energeticCoach: return "Hey! I'm Max. Ready to crush some goals today?"
        case .calmReflective: return "Hello. I'm Luna. Let's take this journey mindfully."
        case .wisePatient: return "Greetings. I'm Sage. Wisdom comes through patient exploration."
        }
    }
}

// MARK: - Companion Mood

/// Dynamic emotional/energy state of the avatar companion
public enum CompanionMood: String, Codable {
    case neutral
    case excited
    case encouraging
    case thoughtful
    case celebrating
    case tired
    case curious
    
    public var color: Color {
        switch self {
        case .neutral: return .blue
        case .excited: return .yellow
        case .encouraging: return .green
        case .thoughtful: return .blue
        case .celebrating: return .purple
        case .tired: return .gray
        case .curious: return .orange
        }
    }
    
    public var emoji: String {
        switch self {
        case .neutral: return "😊"
        case .excited: return "🤩"
        case .encouraging: return "💪"
        case .thoughtful: return "🤔"
        case .celebrating: return "🎉"
        case .tired: return "😌"
        case .curious: return "🧐"
        }
    }
}

// MARK: - User Action

/// Types of user interactions that affect avatar state and mood
public enum UserAction {
    case answeredCorrect
    case answeredIncorrect
    case struggled
    case askedQuestion
    case completedLesson
    case startedSession
}

// MARK: - Companion State

/// Real-time state tracking for avatar companion behavior
public struct CompanionState: Codable {
    public var mood: CompanionMood = .neutral
    public var energy: Float = 1.0  // 0.0-1.0 (affects animation speed)
    public var lastInteraction: Date = Date()
    public var currentActivity: String? = nil  // "Reviewing Fractions", "Quiz Mode"
    public var isSpeaking: Bool = false
    
    public init(
        mood: CompanionMood = .neutral,
        energy: Float = 1.0,
        lastInteraction: Date = Date(),
        currentActivity: String? = nil,
        isSpeaking: Bool = false
    ) {
        self.mood = mood
        self.energy = energy
        self.lastInteraction = lastInteraction
        self.currentActivity = currentActivity
        self.isSpeaking = isSpeaking
    }
    
    public mutating func recordInteraction() {
        lastInteraction = Date()
    }
    
    public mutating func updateMood(for action: UserAction) {
        switch action {
        case .answeredCorrect:
            mood = .celebrating
            energy = min(energy + 0.1, 1.0)
        case .answeredIncorrect:
            mood = .encouraging
        case .struggled:
            mood = .encouraging
        case .askedQuestion:
            mood = .thoughtful
        case .completedLesson:
            mood = .celebrating
            energy = 1.0
        case .startedSession:
            mood = determineStartMood()
        }
    }
    
    private func determineStartMood() -> CompanionMood {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour <= 5 {
            return .tired
        }
        return .curious
    }
}

// MARK: - Avatar Memory

/// Persistent memory and learning history for the avatar companion
public struct AvatarMemory: Codable {
    public var lastSeenDate: Date = Date()
    public var topicsDiscussed: [String] = []
    public var strugglesNoted: [String: Int] = [:]  // "fractions": 3 mentions
    public var achievements: [String] = []
    public var conversationCount: Int = 0
    public var totalStudyMinutes: Int = 0
    
    public init(
        lastSeenDate: Date = Date(),
        topicsDiscussed: [String] = [],
        strugglesNoted: [String: Int] = [:],
        achievements: [String] = [],
        conversationCount: Int = 0,
        totalStudyMinutes: Int = 0
    ) {
        self.lastSeenDate = lastSeenDate
        self.topicsDiscussed = topicsDiscussed
        self.strugglesNoted = strugglesNoted
        self.achievements = achievements
        self.conversationCount = conversationCount
        self.totalStudyMinutes = totalStudyMinutes
    }
    
    public mutating func recordTopic(_ topic: String) {
        if !topicsDiscussed.contains(topic) {
            topicsDiscussed.append(topic)
        }
    }
    
    public mutating func recordStruggle(with topic: String) {
        strugglesNoted[topic, default: 0] += 1
    }
    
    public mutating func recordAchievement(_ description: String) {
        achievements.append("\(Date()): \(description)")
    }
    
    public mutating func recordConversation(durationMinutes: Int) {
        conversationCount += 1
        totalStudyMinutes += durationMinutes
        lastSeenDate = Date()
    }
    
    public var mostChallengingTopic: String? {
        strugglesNoted.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Avatar

/// Main avatar model - requires supporting types from AvatarModels.swift
/// Note: This is a forward declaration. Full implementation with appearance, 
/// profile, and calibration types remains in AvatarModels.swift
/// We only define the minimal interface here to break circular dependencies
public struct Avatar: Codable, Identifiable, Hashable {
    public var id: UUID
    public var name: String
    public var appearance: AvatarAppearance
    public var profile: PersonalityProfile
    public var voiceIdentifier: String?
    public var calibrationAnswers: CalibrationAnswers
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String = "Lyo",
        appearance: AvatarAppearance = AvatarAppearance(),
        profile: PersonalityProfile = PersonalityProfile(basePersonality: .friendlyCurious),
        voiceIdentifier: String? = nil,
        calibrationAnswers: CalibrationAnswers = CalibrationAnswers(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.appearance = appearance
        self.profile = profile
        self.voiceIdentifier = voiceIdentifier
        self.calibrationAnswers = calibrationAnswers
        self.createdAt = createdAt
    }
    
    // Computed properties
    public var personality: Personality {
        profile.basePersonality
    }
    
    public var style: AvatarStyle {
        appearance.style
    }
}

// MARK: - Supporting Types (Minimal definitions - full versions in AvatarModels.swift)

/// Avatar appearance configuration
public struct AvatarAppearance: Codable, Hashable {
    public var style: AvatarStyle
    public var colorScheme: String
    
    public init(
        style: AvatarStyle = .friendlyBot,
        colorScheme: String = "default"
    ) {
        self.style = style
        self.colorScheme = colorScheme
    }
}

/// Avatar personality profile
public struct PersonalityProfile: Codable, Hashable {
    public var basePersonality: Personality
    public var hintFrequency: Double
    public var celebrationIntensity: Double
    public var encouragementStyle: String
    
    public init(
        basePersonality: Personality,
        hintFrequency: Double = 0.5,
        celebrationIntensity: Double = 0.7,
        encouragementStyle: String = "balanced"
    ) {
        self.basePersonality = basePersonality
        self.hintFrequency = hintFrequency
        self.celebrationIntensity = celebrationIntensity
        self.encouragementStyle = encouragementStyle
    }
}

/// Calibration answers from onboarding
public struct CalibrationAnswers: Codable, Hashable {
    public var learningStyle: ScaffoldingStyle
    public var pace: String
    public var motivation: String
    
    public init(
        learningStyle: ScaffoldingStyle = .balanced,
        pace: String = "moderate",
        motivation: String = "intrinsic"
    ) {
        self.learningStyle = learningStyle
        self.pace = pace
        self.motivation = motivation
    }
    
    public func toPersonalityProfile(base: Personality) -> PersonalityProfile {
        var profile = PersonalityProfile(basePersonality: base)
        
        // Adjust hint frequency based on learning style
        switch learningStyle {
        case .examplesFirst:
            profile.hintFrequency = 0.8
        case .theoryFirst:
            profile.hintFrequency = 0.4
        case .challengeBased:
            profile.hintFrequency = 0.3
        case .balanced:
            profile.hintFrequency = 0.5
        }
        
        // Adjust celebration based on pace
        profile.celebrationIntensity = pace == "fast" ? 0.9 : 0.6
        
        return profile
    }
}

/// Scaffolding/learning style preference
public enum ScaffoldingStyle: String, Codable {
    case examplesFirst = "examples"
    case theoryFirst = "theory"
    case challengeBased = "challenges"
    case balanced = "balanced"
}

// MARK: - ============================================================
// MARK: - EXTENSIONS & CONVENIENCE
// MARK: - ============================================================

// MARK: - AIMessage Extensions

extension AIMessage {
    /// Legacy property for compatibility
    public var date: Date { timestamp }
    
    /// Legacy property for compatibility
    public var isUser: Bool { isFromUser }
    
    /// Formatted time string
    public var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Check if message is from AI
    public var isFromAI: Bool { !isFromUser }
    
    /// Short preview of content
    public var preview: String {
        if content.count > 50 {
            return String(content.prefix(47)) + "..."
        }
        return content
    }
}

// MARK: - Avatar Extensions

extension Avatar {
    public var displayEmoji: String {
        style.emoji
    }
    
    public var gradientColors: [Color] {
        style.gradientColors
    }
}

// MARK: - ============================================================
// MARK: - MIGRATION NOTES
// MARK: - ============================================================

/*
 This file consolidates core types to resolve Swift compilation order issues.
 
 Types moved TO this file:
 - AIMessage (from ChatMessage.swift) ✅
 - LearningBlueprint, BlueprintNode (from AIModels.swift) ✅
 - AvatarStyle, Personality, CompanionMood (from AvatarModels.swift) ✅
 - UserAction, CompanionState, AvatarMemory (from AvatarModels.swift) ✅
 - Avatar (minimal definition - full remains in AvatarModels.swift) ✅
 
 Files that now import from CoreTypes:
 - AIModels.swift - uses AIMessage, LearningBlueprint, Avatar
 - AvatarModels.swift - extends Avatar, adds full appearance/calibration types
 - AvatarStore.swift - uses Avatar, CompanionState, AvatarMemory, etc.
 - ChatMessage.swift - now just has extensions
 
 Extensions and methods remain in their original files for organization.
 */
