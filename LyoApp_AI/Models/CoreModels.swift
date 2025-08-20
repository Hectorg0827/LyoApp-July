import Foundation
import SwiftUI

// MARK: - User Model (Compatible with existing codebase)
struct User: Codable, Identifiable {
    var id: String
    var displayName: String
    var email: String
    var profilePictureURL: String?
    var username: String?
    var fullName: String?
    var bio: String?
    var followers: Int?
    var following: Int?
    var posts: Int?
    var level: Int?
    var experience: Int?
    var joinDate: Date?
    
    init(id: String, displayName: String, email: String, profilePictureURL: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.profilePictureURL = profilePictureURL
        self.username = displayName.lowercased().replacingOccurrences(of: " ", with: "_")
        self.fullName = displayName
        self.followers = 0
        self.following = 0
        self.posts = 0
        self.level = 1
        self.experience = 0
        self.joinDate = Date()
    }
}

// MARK: - Authentication Models
struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct Profile: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let fullName: String
    let bio: String?
    let profileImageURL: String?
    let followers: Int
    let following: Int
    let posts: Int
    let level: Int
    let experience: Int
    let joinDate: Date
    let onboardingComplete: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, bio, followers, following, posts, level, experience
        case fullName = "full_name"
        case profileImageURL = "profile_image_url"
        case joinDate = "join_date"
        case onboardingComplete = "onboarding_complete"
    }
}

// MARK: - Course & Learning Models
struct CoursePlan: Codable, Identifiable {
    let id: String
    let goal: LearningGoal
    let modules: [Module]
    let lastUpdated: Date
    let progress: Double
    
    enum CodingKeys: String, CodingKey {
        case id, goal, modules, progress
        case lastUpdated = "last_updated"
    }
}

struct LearningGoal: Codable {
    let title: String
    let description: String?
    let timeframeWeeks: Int?
    let subject: String?
    
    enum CodingKeys: String, CodingKey {
        case title, description, subject
        case timeframeWeeks = "timeframe_weeks"
    }
}

struct Module: Codable, Identifiable {
    let id: String
    let title: String
    let lessons: [Lesson]
    let progress: Double
}

struct Lesson: Codable, Identifiable {
    let id: String
    let title: String
    let objectives: [String]
    let contentRefs: [ContentRef]
    let estimatedMinutes: Int?
    let status: LessonStatus
    
    enum CodingKeys: String, CodingKey {
        case id, title, objectives, status
        case contentRefs = "content_refs"
        case estimatedMinutes = "estimated_minutes"
    }
}

enum LessonStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
}

enum ContentKind: String, Codable, CaseIterable {
    case video, article, ebook, podcast, course
    
    var icon: String {
        switch self {
        case .video: return "play.circle"
        case .article: return "doc.text"
        case .ebook: return "book"
        case .podcast: return "mic"
        case .course: return "graduationcap"
        }
    }
}

struct ContentRef: Codable, Identifiable {
    let id: String
    let kind: ContentKind
    let title: String
    let provider: String?
    let url: URL
    let durationSeconds: Int?
    let thumbURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case id, kind, title, provider, url
        case durationSeconds = "duration_seconds"
        case thumbURL = "thumb_url"
    }
}

// MARK: - Tutor Models
enum TutorEvent: Codable {
    case hint(String)
    case explanation(String)
    case question(QuizItem)
    case planUpdate(CoursePlan)
    case remediation(RemediationPlan)
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    enum EventType: String, Codable {
        case hint, explanation, question, planUpdate, remediation
    }
}

struct TutorTurn: Codable {
    let message: String
    let context: TutorContext?
}

struct TutorContext: Codable {
    let learnerId: String
    let currentLesson: String?
    let recentQuestions: [String]
    let learningStyle: String?
    
    enum CodingKeys: String, CodingKey {
        case learnerId = "learner_id"
        case currentLesson = "current_lesson"
        case recentQuestions = "recent_questions"
        case learningStyle = "learning_style"
    }
}

struct QuizItem: Codable, Identifiable {
    let id: String
    let question: String
    let options: [String]?
    let correctAnswer: String
    let explanation: String?
    let difficulty: QuizDifficulty
}

enum QuizDifficulty: String, Codable, CaseIterable {
    case easy, medium, hard
}

struct QuizResult: Codable {
    let itemId: String
    let userAnswer: String
    let isCorrect: Bool
    let timeSpentSeconds: Int
    
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case userAnswer = "user_answer"
        case isCorrect = "is_correct"
        case timeSpentSeconds = "time_spent_seconds"
    }
}

struct RemediationPlan: Codable {
    let weakAreas: [String]
    let recommendedContent: [ContentRef]
    let suggestedPractice: [QuizItem]
    
    enum CodingKeys: String, CodingKey {
        case weakAreas = "weak_areas"
        case recommendedContent = "recommended_content"
        case suggestedPractice = "suggested_practice"
    }
}

// MARK: - Media Models
struct MediaRef: Codable, Identifiable {
    let id: String
    let url: URL
    let kind: MediaKind
    let metadata: MediaMeta?
}

enum MediaKind: String, Codable, CaseIterable {
    case image, video, audio, document
}

struct MediaMeta: Codable {
    let width: Int?
    let height: Int?
    let duration: Double?
    let fileSize: Int?
    let mimeType: String?
    
    enum CodingKeys: String, CodingKey {
        case width, height, duration
        case fileSize = "file_size"
        case mimeType = "mime_type"
    }
}

struct Presign: Codable {
    let uploadURL: URL
    let mediaId: String
    let fields: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case uploadURL = "upload_url"
        case mediaId = "media_id"
        case fields
    }
}
