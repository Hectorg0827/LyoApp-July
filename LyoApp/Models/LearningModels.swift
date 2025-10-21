import Foundation
import SwiftUI

// MARK: - Learning Blueprint Types (for AI Onboarding Flow)

/// Represents a learning blueprint structure
public struct LearningBlueprint: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let nodes: [BlueprintNode]
    let connectionPath: [String] // IDs of connected nodes
    let createdAt: Date
    let completionPercentage: Double
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        nodes: [BlueprintNode] = [],
        connectionPath: [String] = [],
        createdAt: Date = Date(),
        completionPercentage: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.nodes = nodes
        self.connectionPath = connectionPath
        self.createdAt = createdAt
        self.completionPercentage = completionPercentage
    }
}

/// Represents a single node in a learning blueprint
public struct BlueprintNode: Identifiable, Codable {
    let id: UUID
    let title: String
    let topic: String
    let type: BlueprintNodeType
    let description: String
    let position: CGPoint
    let isCompleted: Bool
    let dependencies: [UUID] // IDs of prerequisite nodes
    let estimatedTime: TimeInterval
    
    init(
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

enum BlueprintNodeType: String, Codable {
    case lesson
    case quiz
    case practice
    case project
    case review
    case assessment
}

// MARK: - Course Outline Types

/// Local representation of a course outline (used in onboarding)
struct CourseOutlineLocal: Identifiable, Codable {
    let id: UUID
    let courseId: String
    let title: String
    let description: String
    let lessonOutlines: [LessonOutlineLocal]
    let estimatedDurationHours: Double
    let difficulty: String
    let topics: [String]
    
    init(
        id: UUID = UUID(),
        courseId: String,
        title: String,
        description: String = "",
        lessonOutlines: [LessonOutlineLocal] = [],
        estimatedDurationHours: Double = 0,
        difficulty: String = "Intermediate",
        topics: [String] = []
    ) {
        self.id = id
        self.courseId = courseId
        self.title = title
        self.description = description
        self.lessonOutlines = lessonOutlines
        self.estimatedDurationHours = estimatedDurationHours
        self.difficulty = difficulty
        self.topics = topics
    }
}

/// Local representation of a lesson in a course
struct LessonOutlineLocal: Identifiable, Codable {
    let id: UUID
    let lessonNumber: Int
    let title: String
    let description: String
    let objectives: [String]
    let estimatedMinutes: Int
    let contentType: String
    
    init(
        id: UUID = UUID(),
        lessonNumber: Int,
        title: String,
        description: String = "",
        objectives: [String] = [],
        estimatedMinutes: Int = 30,
        contentType: String = "video"
    ) {
        self.id = id
        self.lessonNumber = lessonNumber
        self.title = title
        self.description = description
        self.objectives = objectives
        self.estimatedMinutes = estimatedMinutes
        self.contentType = contentType
    }
}

// MARK: - Conversation Types

/// Represents a message in a conversation
struct ConversationMessage: Identifiable, Codable {
    let id: UUID
    let senderType: MessageSenderType
    let content: String
    let timestamp: Date
    let metadata: MessageMetadata?
    
    init(
        id: UUID = UUID(),
        senderType: MessageSenderType,
        content: String,
        timestamp: Date = Date(),
        metadata: MessageMetadata? = nil
    ) {
        self.id = id
        self.senderType = senderType
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

enum MessageSenderType: String, Codable {
    case user
    case ai
    case system
}

struct MessageMetadata: Codable {
    let sentiment: String?
    let intent: String?
    let confidence: Double?
}

/// Represents a suggested response option
struct SuggestedResponse: Identifiable, Codable {
    let id: UUID
    let text: String
    let relevanceScore: Double
    let category: String
    
    init(
        id: UUID = UUID(),
        text: String,
        relevanceScore: Double = 0.5,
        category: String = "general"
    ) {
        self.id = id
        self.text = text
        self.relevanceScore = relevanceScore
        self.category = category
    }
}

// MARK: - Learning Resource Types

/// Represents a learning resource (lesson, course, etc.)
struct LearningResource: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let resourceType: String
    let contentUrl: String?
    let duration: TimeInterval
    let difficulty: String
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        resourceType: String = "video",
        contentUrl: String? = nil,
        duration: TimeInterval = 0,
        difficulty: String = "Intermediate"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.resourceType = resourceType
        self.contentUrl = contentUrl
        self.duration = duration
        self.difficulty = difficulty
    }
}

// MARK: - User Types (Core user models)

/// Represents a user in the system
struct User: Identifiable, Codable {
    let id: UUID
    let username: String
    let email: String
    let displayName: String
    let avatarUrl: String?
    let joinedDate: Date
    let isVerified: Bool
    
    init(
        id: UUID = UUID(),
        username: String,
        email: String,
        displayName: String,
        avatarUrl: String? = nil,
        joinedDate: Date = Date(),
        isVerified: Bool = false
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.joinedDate = joinedDate
        self.isVerified = isVerified
    }
}

/// Represents a feed post
struct FeedPost: Identifiable, Codable {
    let id: UUID
    let authorId: UUID
    let content: String
    let createdAt: Date
    let likes: Int
    let comments: Int
    let shares: Int
    
    init(
        id: UUID = UUID(),
        authorId: UUID,
        content: String,
        createdAt: Date = Date(),
        likes: Int = 0,
        comments: Int = 0,
        shares: Int = 0
    ) {
        self.id = id
        self.authorId = authorId
        self.content = content
        self.createdAt = createdAt
        self.likes = likes
        self.comments = comments
        self.shares = shares
    }
}

// MARK: - Supporting Lesson Types

public struct Lesson: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String = ""
    ) {
        self.id = id
        self.title = title
        self.content = content
    }
}

public struct MicroQuiz: Identifiable, Codable {
    let id: UUID
    let questionId: UUID
    let quizType: String
    
    init(
        id: UUID = UUID(),
        questionId: UUID = UUID(),
        quizType: String = "multiple_choice"
    ) {
        self.id = id
        self.questionId = questionId
        self.quizType = quizType
    }
}

public struct LessonNote: Identifiable, Codable {
    let id: UUID
    let lessonId: UUID
    let content: String
    
    init(
        id: UUID = UUID(),
        lessonId: UUID = UUID(),
        content: String = ""
    ) {
        self.id = id
        self.lessonId = lessonId
        self.content = content
    }
}

public struct ContentCard: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String = ""
    ) {
        self.id = id
        self.title = title
        self.content = content
    }
}

public struct LessonChunk: Identifiable, Codable {
    let id: UUID
    let sequenceNumber: Int
    let content: String
    
    init(
        id: UUID = UUID(),
        sequenceNumber: Int = 0,
        content: String = ""
    ) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.content = content
    }
}

// MARK: - AI Chat Message Types

struct AIMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let sender: String
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        content: String,
        sender: String = "ai",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
    }
}

public struct ChatConversation: Identifiable, Codable {
    let id: UUID
    let title: String
    let messages: [AIMessage]
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        messages: [AIMessage] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
    }
}

struct UserBadge: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let iconUrl: String?
    let earnedDate: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        iconUrl: String? = nil,
        earnedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconUrl = iconUrl
        self.earnedDate = earnedDate
    }
}

struct Post: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String = ""
    ) {
        self.id = id
        self.title = title
        self.content = content
    }
}

struct ClassroomCourse: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = ""
    ) {
        self.id = id
        self.title = title
        self.description = description
    }
}

// MARK: - System Health Response

struct SystemHealthResponse: Codable {
    let status: String
    let timestamp: Date
    let services: [String: String]
    
    init(
        status: String = "healthy",
        timestamp: Date = Date(),
        services: [String: String] = [:]
    ) {
        self.status = status
        self.timestamp = timestamp
        self.services = services
    }
}

// MARK: - CGPoint Codable Extension
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}
