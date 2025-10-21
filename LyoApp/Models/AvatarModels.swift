//
//  AvatarModels.swift
//  LyoApp
//
//  Enhanced Avatar System - Memoji-style personalized AI companion
//  Created: October 6, 2025
//
//  NOTE: Core types (Avatar, AvatarStyle, Personality, CompanionMood, CompanionState, 
//        AvatarMemory, UserAction) are now defined in CoreTypes.swift
//        This file contains supporting types, extensions, and helper structures
//

import SwiftUI
import AVFoundation

// Core types are defined in CoreTypes.swift:
// - Avatar, AvatarStyle, Personality, CompanionMood, CompanionState, AvatarMemory, UserAction

// MARK: - Supporting Avatar Types
// AvatarStyle is now defined in Models.swift - adding extensions here

// MARK: - Personality Extensions
// Personality base enum is defined in Models.swift
// Adding extended computed properties here

extension Personality {
    var systemPrompt: String {
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

    var tagline: String {
        switch self {
        case .friendlyCurious: return "Warm, curious mentor who asks questions first"
        case .energeticCoach: return "High-energy coach who celebrates your wins"
        case .calmReflective: return "Calm guide who creates space for reflection"
        case .wisePatient: return "Patient tutor who connects concepts deeply"
        }
    }

    var sampleGreeting: String {
        switch self {
        case .friendlyCurious: return "Hi! I'm Lyo. Let's explore and learn together!"
        case .energeticCoach: return "Hey! I'm Max. Ready to crush some goals today?"
        case .calmReflective: return "Hello. I'm Luna. Let's take this journey mindfully."
        case .wisePatient: return "Greetings. I'm Sage. Wisdom comes through patient exploration."
        }
    }
}

// MARK: - CompanionMood Extensions
// CompanionMood base enum is defined in Models.swift

extension CompanionMood {
    var color: Color {
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

    var emoji: String {
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

// MARK: - ScaffoldingStyle Extensions
// ScaffoldingStyle is defined in Models.swift

extension ScaffoldingStyle {
    var description: String {
        switch self {
        case .examplesFirst: return "Show examples first, then explain"
        case .theoryFirst: return "Teach theory, then practice"
        case .challengeBased: return "Learn through quick challenges"
        case .balanced: return "Mix theory and practice"
        }
    }
}

// MARK: - PersonalityProfile Extensions
// PersonalityProfile is defined in Models.swift

extension PersonalityProfile {
    // Adapt based on user behavior (future enhancement)
    public mutating func adapt(skipHints: Bool) {
        if skipHints {
            hintFrequency = max(hintFrequency - 0.1, 0.0)
        }
    }

    public mutating func adapt(respondsWellToCelebration: Bool) {
        if respondsWellToCelebration {
            celebrationIntensity = min(celebrationIntensity + 0.1, 1.0)
        }
    }

    public mutating func adapt(rushesThrough: Bool) {
        if rushesThrough {
            pacePreference = min(pacePreference + 0.1, 1.0)
        }
    }
}

// MARK: - AvatarAppearance, CompanionState, AvatarMemory, UserAction
// All these types are now defined in Models.swift
// Adding extensions for methods here

extension CompanionState {
    mutating func recordInteraction() {
        lastInteraction = Date()
    }

    mutating func updateMood(for action: UserAction) {
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

extension AvatarMemory {
    mutating func recordTopic(_ topic: String) {
        if !topicsDiscussed.contains(topic) {
            topicsDiscussed.append(topic)
        }
    }

    mutating func recordStruggle(with topic: String) {
        strugglesNoted[topic, default: 0] += 1
    }

    mutating func recordAchievement(_ description: String) {
        achievements.append("\(Date()): \(description)")
    }

    mutating func recordConversation(durationMinutes: Int) {
        conversationCount += 1
        totalStudyMinutes += durationMinutes
        lastSeenDate = Date()
    }
}

// MARK: - CalibrationAnswers, Avatar Extensions
// CalibrationAnswers and Avatar are defined in Models.swift
// Adding extensions and factory methods here

extension CalibrationAnswers {
    public func toPersonalityProfile(base: Personality) -> PersonalityProfile {
        var profile = PersonalityProfile(basePersonality: base)

        // Map calibration to profile settings
        profile.scaffoldingStyle = learningStyle

        switch pace {
        case "slow": profile.pacePreference = 0.3
        case "fast": profile.pacePreference = 0.8
        default: profile.pacePreference = 0.5
        }

        switch motivation {
        case "gamified": profile.celebrationIntensity = 0.9
        case "data": profile.celebrationIntensity = 0.4
        default: profile.celebrationIntensity = 0.7
        }

        switch challengePreference {
        case "easy": profile.hintFrequency = 0.8
        case "hard": profile.hintFrequency = 0.3
        default: profile.hintFrequency = 0.5
        }

        return profile
    }
}

extension Avatar {
    var displayEmoji: String {
        style.emoji
    }

    var gradientColors: [Color] {
        style.gradientColors
    }

    // Smart defaults from diagnostic blueprint
    static func fromDiagnostic(_ blueprint: LearningBlueprint) -> Avatar {
        var avatar = Avatar()

        // Map diagnostic goals to personality
        let goals = blueprint.learningGoals.lowercased()
        if goals.contains("career") || goals.contains("professional") {
            avatar.profile.basePersonality = .energeticCoach
            avatar.appearance.style = .energeticCoach
            avatar.name = "Max"
        } else if goals.contains("personal") || goals.contains("hobby") {
            avatar.profile.basePersonality = .friendlyCurious
            avatar.appearance.style = .friendlyBot
            avatar.name = "Lyo"
        } else if goals.contains("deep") || goals.contains("mastery") {
            avatar.profile.basePersonality = .wisePatient
            avatar.appearance.style = .wiseMentor
            avatar.name = "Sage"
        }

        // Map learning style to scaffolding
        if blueprint.preferredStyle.contains("example") {
            avatar.calibrationAnswers.learningStyle = .examplesFirst
        } else if blueprint.preferredStyle.contains("theory") {
            avatar.calibrationAnswers.learningStyle = .theoryFirst
        } else if blueprint.preferredStyle.contains("practice") {
            avatar.calibrationAnswers.learningStyle = .challengeBased
        }

        // Map timeline to pace
        if let timeline = blueprint.timeline {
            if timeline <= 30 {  // 1 month or less
                avatar.calibrationAnswers.pace = "fast"
            } else if timeline >= 180 {  // 6 months+
                avatar.calibrationAnswers.pace = "slow"
            }
        }

        // Create profile from calibration
        avatar.profile = avatar.calibrationAnswers.toPersonalityProfile(base: avatar.profile.basePersonality)

        return avatar
    }
}
