//
//  ChatMessage.swift
//  LyoApp
//
//  Core type definitions - Consolidated to ensure compilation visibility
//  This file is IN the build target and will be compiled
//

import Foundation
import SwiftUI

// MARK: - AI MESSAGE
public struct AIMessage: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let content: String
    public let isFromUser: Bool
    public let timestamp: Date
    public let messageType: MessageType
    public let interactionId: Int?
    
    public enum MessageType: String, Codable {
        case text, code, explanation, quiz, resource, system
    }
    
    public init(id: UUID = UUID(), content: String, isFromUser: Bool, timestamp: Date = Date(), messageType: MessageType = .text, interactionId: Int? = nil) {
        self.id = id; self.content = content; self.isFromUser = isFromUser; self.timestamp = timestamp; self.messageType = messageType; self.interactionId = interactionId
    }
}

public typealias ChatMessage = AIMessage

// MARK: - LEARNING BLUEPRINT
public struct LearningBlueprint: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let nodes: [BlueprintNode]
    public let connectionPath: [String]
    public let createdAt: Date
    public let completionPercentage: Double
    public var learningGoals: String
    public var preferredStyle: String
    public var timeline: Int?
    
    public init(id: UUID = UUID(), title: String, description: String = "", nodes: [BlueprintNode] = [], connectionPath: [String] = [], createdAt: Date = Date(), completionPercentage: Double = 0.0, learningGoals: String = "", preferredStyle: String = "", timeline: Int? = nil) {
        self.id = id; self.title = title; self.description = description; self.nodes = nodes; self.connectionPath = connectionPath; self.createdAt = createdAt; self.completionPercentage = completionPercentage; self.learningGoals = learningGoals; self.preferredStyle = preferredStyle; self.timeline = timeline
    }
}

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
    
    public init(id: UUID = UUID(), title: String, topic: String, type: BlueprintNodeType = .lesson, description: String = "", position: CGPoint = .zero, isCompleted: Bool = false, dependencies: [UUID] = [], estimatedTime: TimeInterval = 300) {
        self.id = id; self.title = title; self.topic = topic; self.type = type; self.description = description; self.position = position; self.isCompleted = isCompleted; self.dependencies = dependencies; self.estimatedTime = estimatedTime
    }
}

public enum BlueprintNodeType: String, Codable {
    case lesson, quiz, practice, project, review, assessment
}

// MARK: - AVATAR TYPES
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

public enum Personality: String, Codable, CaseIterable, Identifiable {
    case friendlyCurious = "Lyo"
    case energeticCoach = "Max"
    case calmReflective = "Luna"
    case wisePatient = "Sage"
    
    public var id: String { rawValue }
    public var systemPrompt: String {
        switch self {
        case .friendlyCurious: return "You are Lyo, a warm and curious learning companion."
        case .energeticCoach: return "You are Max, a high-energy motivational coach."
        case .calmReflective: return "You are Luna, a calm and reflective guide."
        case .wisePatient: return "You are Sage, a patient Socratic tutor."
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

public enum CompanionMood: String, Codable {
    case neutral, excited, encouraging, thoughtful, celebrating, tired, curious
    public var color: Color {
        switch self {
        case .neutral: return .blue; case .excited: return .yellow; case .encouraging: return .green
        case .thoughtful: return .blue; case .celebrating: return .purple; case .tired: return .gray; case .curious: return .orange
        }
    }
    public var emoji: String {
        switch self {
        case .neutral: return "😊"; case .excited: return "🤩"; case .encouraging: return "💪"
        case .thoughtful: return "🤔"; case .celebrating: return "🎉"; case .tired: return "😌"; case .curious: return "🧐"
        }
    }
}

public enum UserAction {
    case answeredCorrect, answeredIncorrect, struggled, askedQuestion, completedLesson, startedSession
}

public struct CompanionState: Codable {
    public var mood: CompanionMood = .neutral
    public var energy: Float = 1.0
    public var lastInteraction: Date = Date()
    public var currentActivity: String? = nil
    public var isSpeaking: Bool = false
    
    public init(mood: CompanionMood = .neutral, energy: Float = 1.0, lastInteraction: Date = Date(), currentActivity: String? = nil, isSpeaking: Bool = false) {
        self.mood = mood; self.energy = energy; self.lastInteraction = lastInteraction; self.currentActivity = currentActivity; self.isSpeaking = isSpeaking
    }
    
    public mutating func recordInteraction() { lastInteraction = Date() }
    public mutating func updateMood(for action: UserAction) {
        switch action {
        case .answeredCorrect: mood = .celebrating; energy = min(energy + 0.1, 1.0)
        case .answeredIncorrect, .struggled: mood = .encouraging
        case .askedQuestion: mood = .thoughtful
        case .completedLesson: mood = .celebrating; energy = 1.0
        case .startedSession: mood = .curious
        }
    }
}

public struct AvatarMemory: Codable {
    public var lastSeenDate: Date = Date()
    public var topicsDiscussed: [String] = []
    public var strugglesNoted: [String: Int] = [:]
    public var achievements: [String] = []
    public var conversationCount: Int = 0
    public var totalStudyMinutes: Int = 0
    
    public init(lastSeenDate: Date = Date(), topicsDiscussed: [String] = [], strugglesNoted: [String: Int] = [:], achievements: [String] = [], conversationCount: Int = 0, totalStudyMinutes: Int = 0) {
        self.lastSeenDate = lastSeenDate; self.topicsDiscussed = topicsDiscussed; self.strugglesNoted = strugglesNoted; self.achievements = achievements; self.conversationCount = conversationCount; self.totalStudyMinutes = totalStudyMinutes
    }
    
    public mutating func recordTopic(_ topic: String) { if !topicsDiscussed.contains(topic) { topicsDiscussed.append(topic) } }
    public mutating func recordStruggle(with topic: String) { strugglesNoted[topic, default: 0] += 1 }
    public mutating func recordAchievement(_ description: String) { achievements.append("\(Date()): \(description)") }
    public mutating func recordConversation(durationMinutes: Int) { conversationCount += 1; totalStudyMinutes += durationMinutes; lastSeenDate = Date() }
    public var mostChallengingTopic: String? { strugglesNoted.max(by: { $0.value < $1.value })?.key }
}

// MARK: - Avatar types are now in Models.swift - DO NOT DEFINE HERE
// These were causing duplicate symbol and compilation order issues
/*
public struct Avatar: Codable, Identifiable, Hashable {
    public var id: UUID
    public var name: String
    public var appearance: AvatarAppearance
    public var profile: PersonalityProfile
    public var voiceIdentifier: String?
    public var calibrationAnswers: CalibrationAnswers
    public var createdAt: Date
    
    public init(id: UUID = UUID(), name: String = "Lyo", appearance: AvatarAppearance = AvatarAppearance(), profile: PersonalityProfile = PersonalityProfile(basePersonality: .friendlyCurious), voiceIdentifier: String? = nil, calibrationAnswers: CalibrationAnswers = CalibrationAnswers(), createdAt: Date = Date()) {
        self.id = id; self.name = name; self.appearance = appearance; self.profile = profile; self.voiceIdentifier = voiceIdentifier; self.calibrationAnswers = calibrationAnswers; self.createdAt = createdAt
    }
    
    public var personality: Personality { profile.basePersonality }
    public var style: AvatarStyle { appearance.style }
}

public struct AvatarAppearance: Codable, Hashable {
    public var style: AvatarStyle
    public var colorScheme: String
    public init(style: AvatarStyle = .friendlyBot, colorScheme: String = "default") {
        self.style = style; self.colorScheme = colorScheme
    }
}

public struct PersonalityProfile: Codable, Hashable {
    public var basePersonality: Personality
    public var hintFrequency: Double
    public var celebrationIntensity: Double
    public var encouragementStyle: String
    public init(basePersonality: Personality, hintFrequency: Double = 0.5, celebrationIntensity: Double = 0.7, encouragementStyle: String = "balanced") {
        self.basePersonality = basePersonality; self.hintFrequency = hintFrequency; self.celebrationIntensity = celebrationIntensity; self.encouragementStyle = encouragementStyle
    }
}

public struct CalibrationAnswers: Codable, Hashable {
    public var learningStyle: ScaffoldingStyle
    public var pace: String
    public var motivation: String
    public init(learningStyle: ScaffoldingStyle = .balanced, pace: String = "moderate", motivation: String = "intrinsic") {
        self.learningStyle = learningStyle; self.pace = pace; self.motivation = motivation
    }
    public func toPersonalityProfile(base: Personality) -> PersonalityProfile {
        var profile = PersonalityProfile(basePersonality: base)
        switch learningStyle {
        case .examplesFirst: profile.hintFrequency = 0.8
        case .theoryFirst: profile.hintFrequency = 0.4
        case .challengeBased: profile.hintFrequency = 0.3
        case .balanced: profile.hintFrequency = 0.5
        }
        profile.celebrationIntensity = pace == "fast" ? 0.9 : 0.6
        return profile
    }
}

public enum ScaffoldingStyle: String, Codable {
    case examplesFirst = "examples", theoryFirst = "theory", challengeBased = "challenges", balanced = "balanced"
}

// Extensions
extension AIMessage {
    public var date: Date { timestamp }
    public var isUser: Bool { isFromUser }
    public var isFromAI: Bool { !isFromUser }
}
extension Avatar {
    public var displayEmoji: String { style.emoji }
    public var gradientColors: [Color] { style.gradientColors }
}
