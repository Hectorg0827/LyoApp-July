import Foundation
import SwiftUI

// MARK: - Enhanced Learning Resource Data Model
/// Unified data model for all educational content in the Learning Hub
struct LearningResource: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let contentType: ContentType
    let sourcePlatform: SourcePlatform
    let authorCreator: String?
    let tags: [String]
    
    // Safe URL handling - store as strings and provide computed properties
    private let thumbnailURLString: String
    private let contentURLString: String
    let publishedAt: Date?
    
    // Enhanced Fields for rich user experience
    let difficultyLevel: DifficultyLevel?
    let estimatedDuration: String? // "1h 30m"
    let rating: Double?
    let language: String?
    let viewCount: Int?
    let isBookmarked: Bool
    let isFavorite: Bool
    let progress: Double? // 0.0 to 1.0 for completed percentage
    
    // Additional enhanced fields
    let category: String?
    let instructor: String?
    let prerequisites: [String]?
    let learningOutcomes: [String]?
    let lastAccessedAt: Date?
    let completionCertificate: Bool
    let price: Double? // For paid content
    let currency: String?
    
    // Metadata
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Safe URL Computed Properties
    var thumbnailURL: URL? {
        URL(string: thumbnailURLString)
    }
    
    var contentURL: URL? {
        URL(string: contentURLString)
    }
    
    // MARK: - Coding Keys for JSON Mapping
    private enum CodingKeys: String, CodingKey {
        case id, title, description, contentType, sourcePlatform, authorCreator, tags, publishedAt
        case thumbnailURLString = "thumbnailURL"
        case contentURLString = "contentURL"
        case difficultyLevel, estimatedDuration, rating, language, viewCount
        case isBookmarked, isFavorite, progress, category, instructor
        case prerequisites, learningOutcomes, lastAccessedAt, completionCertificate
        case price, currency, createdAt, updatedAt
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        contentType: ContentType,
        sourcePlatform: SourcePlatform,
        authorCreator: String? = nil,
        tags: [String] = [],
        thumbnailURL: URL,
        contentURL: URL,
        publishedAt: Date? = nil,
        difficultyLevel: DifficultyLevel? = nil,
        estimatedDuration: String? = nil,
        rating: Double? = nil,
        language: String? = "en",
        viewCount: Int? = nil,
        isBookmarked: Bool = false,
        isFavorite: Bool = false,
        progress: Double? = nil,
        category: String? = nil,
        instructor: String? = nil,
        prerequisites: [String]? = nil,
        learningOutcomes: [String]? = nil,
        lastAccessedAt: Date? = nil,
        completionCertificate: Bool = false,
        price: Double? = nil,
        currency: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.contentType = contentType
        self.sourcePlatform = sourcePlatform
        self.authorCreator = authorCreator
        self.tags = tags
        self.thumbnailURLString = thumbnailURL.absoluteString
        self.contentURLString = contentURL.absoluteString
        self.publishedAt = publishedAt
        self.difficultyLevel = difficultyLevel
        self.estimatedDuration = estimatedDuration
        self.rating = rating
        self.language = language
        self.viewCount = viewCount
        self.isBookmarked = isBookmarked
        self.isFavorite = isFavorite
        self.progress = progress
        self.category = category
        self.instructor = instructor
        self.prerequisites = prerequisites
        self.learningOutcomes = learningOutcomes
        self.lastAccessedAt = lastAccessedAt
        self.completionCertificate = completionCertificate
        self.price = price
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Supporting Enums
extension LearningResource {
    enum ContentType: String, CaseIterable, Codable {
        case video = "video"
        case ebook = "ebook"
        case podcast = "podcast"
        case course = "course"
        case article = "article"
        
        var displayName: String {
            switch self {
            case .video: return "Video"
            case .ebook: return "E-book"
            case .podcast: return "Podcast"
            case .course: return "Course"
            case .article: return "Article"
            }
        }
        
        var icon: String {
            switch self {
            case .video: return "play.rectangle.fill"
            case .ebook: return "book.fill"
            case .podcast: return "waveform"
            case .course: return "graduationcap.fill"
            case .article: return "doc.text.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .video: return .red
            case .ebook: return .green
            case .podcast: return .purple
            case .course: return .blue
            case .article: return .orange
            }
        }
    }
    
    enum SourcePlatform: String, CaseIterable, Codable {
        case youtube = "youtube"
        case openLibrary = "openlibrary"
        case podchaser = "podchaser"
        case curated = "curated"
        case edx = "edx"
        case coursera = "coursera"
        case udemy = "udemy"
        case khan = "khan"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .youtube: return "YouTube"
            case .openLibrary: return "Open Library"
            case .podchaser: return "Podchaser"
            case .curated: return "Curated"
            case .edx: return "edX"
            case .coursera: return "Coursera"
            case .udemy: return "Udemy"
            case .khan: return "Khan Academy"
            case .custom: return "Custom"
            }
        }
    }
    
    enum DifficultyLevel: String, CaseIterable, Codable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case expert = "expert"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var numericValue: Int {
            switch self {
            case .beginner: return 1
            case .intermediate: return 2
            case .advanced: return 3
            case .expert: return 3
            }
        }
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .yellow
            case .advanced: return .orange
            case .expert: return .red
            }
        }
    }
}

// MARK: - Search and Filter Models
struct LearningSearchRequest: Codable {
    let query: String
    let contentTypes: [LearningResource.ContentType]
    let sourcePlatforms: [LearningResource.SourcePlatform]
    let difficultyLevels: [LearningResource.DifficultyLevel]
    let tags: [String]
    let minRating: Double?
    let language: String?
    let limit: Int
    let offset: Int
    
    init(
        query: String = "",
        contentTypes: [LearningResource.ContentType] = [],
        sourcePlatforms: [LearningResource.SourcePlatform] = [],
        difficultyLevels: [LearningResource.DifficultyLevel] = [],
        tags: [String] = [],
        minRating: Double? = nil,
        language: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) {
        self.query = query
        self.contentTypes = contentTypes
        self.sourcePlatforms = sourcePlatforms
        self.difficultyLevels = difficultyLevels
        self.tags = tags
        self.minRating = minRating
        self.language = language
        self.limit = limit
        self.offset = offset
    }
}

struct LearningSearchResponse: Codable {
    let resources: [LearningResource]
    let totalCount: Int
    let hasMore: Bool
    let nextOffset: Int?
}

// MARK: - Sample Data for Development
extension LearningResource {
    static let sampleResources: [LearningResource] = [
        LearningResource(
            title: "SwiftUI Fundamentals",
            description: "Learn the basics of SwiftUI for iOS development with hands-on examples",
            contentType: .course,
            sourcePlatform: .curated,
            authorCreator: "Apple Developer",
            tags: ["swift", "ios", "mobile", "development"],
            thumbnailURL: URL(string: "https://picsum.photos/320/180?random=1")!,
            contentURL: URL(string: "https://developer.apple.com/tutorials/swiftui")!,
            publishedAt: Date().addingTimeInterval(-86400 * 30),
            difficultyLevel: .beginner,
            estimatedDuration: "3h 45m",
            rating: 4.8,
            viewCount: 15420
        ),
        LearningResource(
            title: "Advanced Swift Patterns",
            description: "Master advanced Swift programming patterns and architectures",
            contentType: .video,
            sourcePlatform: .youtube,
            authorCreator: "Sean Allen",
            tags: ["swift", "patterns", "architecture"],
            thumbnailURL: URL(string: "https://picsum.photos/320/180?random=2")!,
            contentURL: URL(string: "https://youtube.com/watch?v=example")!,
            publishedAt: Date().addingTimeInterval(-86400 * 7),
            difficultyLevel: .advanced,
            estimatedDuration: "1h 20m",
            rating: 4.9,
            viewCount: 8650
        ),
        LearningResource(
            title: "The Swift Programming Language",
            description: "Complete guide to Swift programming from Apple",
            contentType: .ebook,
            sourcePlatform: .openLibrary,
            authorCreator: "Apple Inc.",
            tags: ["swift", "programming", "reference"],
            thumbnailURL: URL(string: "https://picsum.photos/320/180?random=3")!,
            contentURL: URL(string: "https://docs.swift.org/swift-book/")!,
            publishedAt: Date().addingTimeInterval(-86400 * 60),
            difficultyLevel: .intermediate,
            estimatedDuration: "8h read",
            rating: 4.7,
            viewCount: 25000
        ),
        LearningResource(
            title: "Swift by Sundell Podcast",
            description: "Weekly discussions about Swift development and iOS programming",
            contentType: .podcast,
            sourcePlatform: .podchaser,
            authorCreator: "John Sundell",
            tags: ["swift", "ios", "podcast", "discussion"],
            thumbnailURL: URL(string: "https://picsum.photos/320/180?random=4")!,
            contentURL: URL(string: "https://www.swiftbysundell.com/podcast/")!,
            publishedAt: Date().addingTimeInterval(-86400 * 3),
            difficultyLevel: .intermediate,
            estimatedDuration: "45m",
            rating: 4.6,
            viewCount: 12000
        )
    ]
}

// MARK: - Learning Progress Model
/// Represents progress for a specific learning resource
struct LearningProgress: Codable {
    let resourceId: String
    let percentage: Double
    let timeSpent: TimeInterval
    let lastAccessed: Date
    let completed: Bool
    
    init(resourceId: String, percentage: Double, timeSpent: TimeInterval, lastAccessed: Date = Date(), completed: Bool = false) {
        self.resourceId = resourceId
        self.percentage = percentage
        self.timeSpent = timeSpent
        self.lastAccessed = lastAccessed
        self.completed = completed
    }
}
