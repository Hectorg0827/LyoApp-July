import Foundation
import SwiftUI

// MARK: - Content Card (Curated Resources)
// NOTE: CardKind and ContentCard are now defined in ClassroomModels.swift
// This file kept for UserSignals and other supporting types

/*
/// Type of curated content card - MOVED TO ClassroomModels.swift
enum CardKind: String, Codable, CaseIterable {
    case video = "Video"
    case ebook = "eBook"
    case article = "Article"
    case exercise = "Exercise"
    case infographic = "Infographic"
    case dataset = "Dataset"
    case podcast = "Podcast"
    case tool = "Interactive Tool"
    
    var icon: String {
        switch self {
        case .video: return "play.rectangle.fill"
        case .ebook: return "book.fill"
        case .article: return "doc.text.fill"
        case .exercise: return "pencil.and.outline"
        case .infographic: return "chart.bar.fill"
        case .dataset: return "tablecells.fill"
        case .podcast: return "mic.fill"
        case .tool: return "wrench.and.screwdriver.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .video: return .red
        case .ebook: return .orange
        case .article: return .blue
        case .exercise: return .green
        case .infographic: return .purple
        case .dataset: return .cyan
        case .podcast: return .indigo
        case .tool: return .pink
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .video:
            return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ebook:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .article:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .exercise:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .infographic:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dataset:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .podcast:
            return LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .tool:
            return LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

/// A curated content card surfaced during learning - MOVED TO ClassroomModels.swift
struct ContentCard: Codable, Identifiable, Hashable, Equatable {
    var id = UUID()
    var kind: CardKind
    var title: String
    var source: String
    var url: URL
    var estMinutes: Int
    var tags: [String] = []
    var summary: String
    var citation: String
    var thumbnailURL: URL?
    var author: String?
    var publishedDate: String?
    var readingLevel: ReadingLevel = .middle
    var createdDate: Date = Date()
    var relevanceScore: Double = 0.5 // 0.0-1.0
    var qualityScore: Double = 0.7 // 0.0-1.0 (credibility, accuracy)
    var isSaved: Bool = false
    var openedDate: Date?
    var isPinged: Bool = false // For "New card!" animation
    
    mutating func markSaved() {
        isSaved = true
    }
    
    mutating func markOpened() {
        openedDate = Date()
    }
    
    mutating func ping() {
        isPinged = true
    }
    
    var displayDuration: String {
        if estMinutes < 60 {
            return "\(estMinutes) min"
        } else {
            let hours = estMinutes / 60
            let mins = estMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
    
    var formattedCitation: String {
        var parts: [String] = []
        
        if let author = author {
            parts.append(author)
        }
        
        parts.append(title)
        parts.append(source)
        
        if let date = publishedDate {
            parts.append(date)
        }
        
        parts.append(url.absoluteString)
        
        return parts.joined(separator: ". ")
    }
}
*/

// ReadingLevel already defined in LessonModels.swift
// Using existing enum: elementary, middle, high, college

// MARK: - User Signals (for ranking)

/// Signals about user behavior to personalize card surfacing
struct UserSignals: Codable, Equatable {
    var prefersVideo: Bool = true
    var prefersText: Bool = true
    var prefersShortMinutes: Int = 10
    var struggling: Bool = false
    var speedMultiplier: Double = 1.0 // >1 = faster, <1 = slower
    var recentTopics: [String] = []
    var savedCardKinds: [CardKind] = []
    var lastInteractionDate: Date = Date()
    
    mutating func recordStruggle() {
        struggling = true
    }
    
    mutating func recordSuccess() {
        struggling = false
    }
    
    mutating func recordCardOpen(_ card: ContentCard) {
        // Track preferences
        if !savedCardKinds.contains(card.kind) {
            savedCardKinds.append(card.kind)
        }
        lastInteractionDate = Date()
    }
    
    var preferredKinds: [CardKind] {
        var kinds: [CardKind] = []
        if prefersVideo { kinds.append(.video) }
        if prefersText { kinds.append(.article); kinds.append(.ebook) }
        return kinds
    }
}

// MARK: - Learning Objective (for curation)

struct LearningObjective: Codable, Hashable, Equatable {
    var keyword: String
    var description: String
    var priority: Priority = .medium
    var tags: [String] = []
    
    enum Priority: String, Codable, CaseIterable {
        case low, medium, high, critical
        
        var weight: Double {
            switch self {
            case .low: return 0.5
            case .medium: return 1.0
            case .high: return 1.5
            case .critical: return 2.0
            }
        }
    }
}

// MARK: - Session Note

struct SessionNote: Codable, Identifiable, Hashable, Equatable {
    var id = UUID()
    var content: String
    var cardID: UUID?
    var lessonStepID: UUID?
    var timestamp: Date = Date()
    var tags: [String] = []
    var citation: String?
    
    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Card Context (why it was surfaced)

enum CardContext: String, Codable {
    case introduction = "Introduction"
    case remedial = "Review & Practice"
    case deepDive = "Go Deeper"
    case alternative = "Different Perspective"
    case practice = "Hands-On Exercise"
    case assessment = "Check Understanding"
    
    var emoji: String {
        switch self {
        case .introduction: return "👋"
        case .remedial: return "🔄"
        case .deepDive: return "🚀"
        case .alternative: return "🔀"
        case .practice: return "🛠️"
        case .assessment: return "✅"
        }
    }
    
    var description: String {
        switch self {
        case .introduction: return "Get started with the basics"
        case .remedial: return "Need more practice on this topic"
        case .deepDive: return "Ready for advanced material"
        case .alternative: return "Another way to understand this"
        case .practice: return "Apply what you've learned"
        case .assessment: return "Test your understanding"
        }
    }
}

/// A card with context about why it was surfaced
struct ContextualCard: Identifiable, Hashable, Equatable {
    var id = UUID()
    var card: ContentCard
    var context: CardContext
    var reasonShown: String // Human-readable explanation
    
    static func == (lhs: ContextualCard, rhs: ContextualCard) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
