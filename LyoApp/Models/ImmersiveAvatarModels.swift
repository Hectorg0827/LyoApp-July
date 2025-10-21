import Foundation
import SwiftUI

// MARK: - Environment Themes
public enum EnvironmentTheme: String, CaseIterable {
    case cosmic, forest, ocean, quantum, neural, minimal
    
    var backgroundColors: [Color] {
        switch self {
        case .cosmic:
            return [.purple.opacity(0.8), .blue.opacity(0.6), .black]
        case .forest:
            return [.green.opacity(0.7), .brown.opacity(0.5), .black.opacity(0.9)]
        case .ocean:
            return [.blue.opacity(0.8), .cyan.opacity(0.6), .teal.opacity(0.4)]
        case .quantum:
            return [.pink.opacity(0.7), .purple.opacity(0.8), .indigo.opacity(0.6)]
        case .neural:
            return [.cyan.opacity(0.6), .blue.opacity(0.7), .indigo.opacity(0.8)]
        case .minimal:
            return [.gray.opacity(0.3), .black.opacity(0.7), .white.opacity(0.1)]
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .cosmic: return .purple
        case .forest: return .green
        case .ocean: return .cyan
        case .quantum: return .pink
        case .neural: return .blue
        case .minimal: return .gray
        }
    }
    
    var shapeCount: Int {
        switch self {
        case .cosmic: return 8
        case .forest: return 5
        case .ocean: return 6
        case .quantum: return 12
        case .neural: return 10
        case .minimal: return 3
        }
    }
}

// MARK: - Avatar Personalities
enum AvatarPersonality: String, CaseIterable {
    case mentor, explorer, scientist, artist, philosopher, engineer
    
    var displayName: String {
        switch self {
        case .mentor: return "Mentor"
        case .explorer: return "Explorer"
        case .scientist: return "Scientist"
        case .artist: return "Artist"
        case .philosopher: return "Philosopher"
        case .engineer: return "Engineer"
        }
    }
    
    var iconName: String {
        switch self {
        case .mentor: return "graduationcap.fill"
        case .explorer: return "safari.fill"
        case .scientist: return "flask.fill"
        case .artist: return "paintbrush.fill"
        case .philosopher: return "brain.head.profile"
        case .engineer: return "gearshape.fill"
        }
    }
    
    var coreColors: [Color] {
        switch self {
        case .mentor:
            return [.blue, .indigo, .purple]
        case .explorer:
            return [.orange, .red, .yellow]
        case .scientist:
            return [.green, .teal, .cyan]
        case .artist:
            return [.pink, .purple, .red]
        case .philosopher:
            return [.indigo, .purple, .blue]
        case .engineer:
            return [.gray, .blue, .cyan]
        }
    }
    
    var glowColors: [Color] {
        switch self {
        case .mentor:
            return [.blue.opacity(0.8), .indigo.opacity(0.6), .clear]
        case .explorer:
            return [.orange.opacity(0.8), .red.opacity(0.6), .clear]
        case .scientist:
            return [.green.opacity(0.8), .teal.opacity(0.6), .clear]
        case .artist:
            return [.pink.opacity(0.8), .purple.opacity(0.6), .clear]
        case .philosopher:
            return [.indigo.opacity(0.8), .purple.opacity(0.6), .clear]
        case .engineer:
            return [.gray.opacity(0.8), .blue.opacity(0.6), .clear]
        }
    }
}

// MARK: - Conversation Mode
public enum ConversationMode: String, CaseIterable {
    case friendly, professional, creative, analytical, supportive
    
    var displayName: String {
        switch self {
        case .friendly: return "Friendly"
        case .professional: return "Professional"
        case .creative: return "Creative"
        case .analytical: return "Analytical"
        case .supportive: return "Supportive"
        }
    }
}

// MARK: - Learning Context
struct LearningContext {
    let currentTopic: String?
    let difficulty: String
    let progress: Double
    let objectives: [String]
    let completedMilestones: [String]
    
    init(currentTopic: String? = nil, difficulty: String = "intermediate", progress: Double = 0.0, objectives: [String] = [], completedMilestones: [String] = []) {
        self.currentTopic = currentTopic
        self.difficulty = difficulty
        self.progress = progress
        self.objectives = objectives
        self.completedMilestones = completedMilestones
    }
}

// MARK: - Course Difficulty
enum CourseDifficulty: String, Codable, CaseIterable {
    case beginner, intermediate, advanced, expert
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
        case .expert: return "star.circle.fill"
        }
    }
}