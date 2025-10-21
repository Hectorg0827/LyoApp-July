import Foundation
import SwiftUI

// MARK: - Learning Resource Model
/// Enhanced model for learning resources with additional fields and enums

struct LegacyLearningResource: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let category: String?
    let difficulty: String?
    let duration: Int?
    let thumbnailUrl: String?
    let imageUrl: String?
    let url: String?
    let provider: String?
    let providerName: String?
    let providerUrl: String?
    let enrolledCount: Int?
    let isEnrolled: Bool?
    let reviews: Int?
    let updatedAt: String?
    let createdAt: String?
    
    // Enhanced properties
    let authorCreator: String?
    let estimatedDuration: String?
    let rating: Double?
    let difficultyLevel: DifficultyLevel?
    let contentType: ContentType
    let resourcePlatform: ResourcePlatform?
    let tags: [String]?
    let isBookmarked: Bool
    let progress: Double?
    let publishedDate: Date?
    
    // UI Computed properties
    var thumbnailURL: URL? {
        guard let urlString = thumbnailUrl else { return nil }
        return URL(string: urlString)
    }
    
    var contentURL: URL? {
        guard let urlString = url ?? providerUrl else { return nil }
        return URL(string: urlString)
    }
    
    // Enums
    enum DifficultyLevel: String, Codable, CaseIterable {
        case beginner
        case intermediate
        case advanced
        case expert
        
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
    }
    
    enum ContentType: String, Codable, CaseIterable {
        case article
        case video
        case course
        case book
        case podcast
        case tutorial
        case documentation
        
        var displayName: String {
            switch self {
            case .article: return "Article"
            case .video: return "Video"
            case .course: return "Course"
            case .book: return "Book"
            case .podcast: return "Podcast"
            case .tutorial: return "Tutorial"
            case .documentation: return "Documentation"
            }
        }
        
        var icon: String {
            switch self {
            case .article: return "doc.text"
            case .video: return "play.rectangle"
            case .course: return "books.vertical"
            case .book: return "book"
            case .podcast: return "mic"
            case .tutorial: return "list.bullet.rectangle"
            case .documentation: return "doc"
            }
        }
    }
    
    enum ResourcePlatform: String, Codable, CaseIterable {
        case youtube
        case udemy
        case coursera
        case medium
        case apple
        case google
        case edx
        case lyo
        case other
        
        var displayName: String {
            switch self {
            case .youtube: return "YouTube"
            case .udemy: return "Udemy"
            case .coursera: return "Coursera"
            case .medium: return "Medium"
            case .apple: return "Apple"
            case .google: return "Google"
            case .edx: return "edX"
            case .lyo: return "Lyo"
            case .other: return "Other"
            }
        }
    }
    
    // Default initializer
    init(
        id: String,
        title: String,
        description: String,
        category: String? = nil,
        difficulty: String? = nil,
        duration: Int? = nil,
        thumbnailUrl: String? = nil,
        imageUrl: String? = nil,
        url: String? = nil,
        provider: String? = nil,
        providerName: String? = nil,
        providerUrl: String? = nil,
        enrolledCount: Int? = nil,
        isEnrolled: Bool? = nil,
        reviews: Int? = nil,
        updatedAt: String? = nil,
        createdAt: String? = nil,
        authorCreator: String? = nil,
        estimatedDuration: String? = nil,
        rating: Double? = nil,
        difficultyLevel: DifficultyLevel? = nil,
        contentType: ContentType = .article,
        resourcePlatform: ResourcePlatform? = nil,
        tags: [String]? = nil,
        isBookmarked: Bool = false,
        progress: Double? = nil,
        publishedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.duration = duration
        self.thumbnailUrl = thumbnailUrl
        self.imageUrl = imageUrl
        self.url = url
        self.provider = provider
        self.providerName = providerName
        self.providerUrl = providerUrl
        self.enrolledCount = enrolledCount
        self.isEnrolled = isEnrolled
        self.reviews = reviews
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.authorCreator = authorCreator
        self.estimatedDuration = estimatedDuration
        self.rating = rating
        self.difficultyLevel = difficultyLevel
        self.contentType = contentType
        self.resourcePlatform = resourcePlatform
        self.tags = tags
        self.isBookmarked = isBookmarked
        self.progress = progress
        self.publishedDate = publishedDate
    }
    
    // UUID-based initializer for convenience
    init(
        id: UUID,
        title: String,
        description: String,
        contentType: ContentType,
        sourcePlatform: ResourcePlatform,
        authorCreator: String?,
        tags: [String],
        thumbnailURL: URL,
        contentURL: URL,
        publishedAt: Date?,
        estimatedDuration: String?,
        rating: Double?,
        language: String?,
        viewCount: Int?,
        isBookmarked: Bool,
        isFavorite: Bool,
        progress: Double?,
        category: String?,
        instructor: String?,
        prerequisites: [String]?,
        learningOutcomes: [String]?,
        lastAccessedAt: Date?,
        completionCertificate: Bool,
        price: Double?,
        currency: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id.uuidString
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = nil
        self.duration = nil
        self.thumbnailUrl = thumbnailURL.absoluteString
        self.imageUrl = nil
        self.url = contentURL.absoluteString
        self.provider = nil
        self.providerName = instructor
        self.providerUrl = nil
        self.enrolledCount = viewCount
        self.isEnrolled = false
        self.reviews = nil
        self.updatedAt = ISO8601DateFormatter().string(from: updatedAt)
        self.createdAt = ISO8601DateFormatter().string(from: createdAt)
        self.authorCreator = authorCreator
        self.estimatedDuration = estimatedDuration
        self.rating = rating
        self.difficultyLevel = nil
        self.contentType = contentType
        self.resourcePlatform = sourcePlatform
        self.tags = tags
        self.isBookmarked = isBookmarked
        self.progress = progress
        self.publishedDate = publishedAt
    }
    
    // Sample data generator for UI development
    static func sampleResources() -> [LegacyLearningResource] {
        [
            LegacyLearningResource(
                id: "1",
                title: "SwiftUI Essentials",
                description: "Learn the fundamentals of SwiftUI, Apple's modern UI framework for building user interfaces across all Apple platforms.",
                category: "Programming",
                difficulty: "intermediate",
                duration: 120,
                thumbnailUrl: "https://images.unsplash.com/photo-1536714848634-df237cf3afe9?q=80&w=1470&auto=format&fit=crop",
                imageUrl: nil,
                url: "https://example.com/swiftui-essentials",
                provider: "Apple",
                providerName: "Apple Developer",
                providerUrl: "https://developer.apple.com/tutorials/swiftui",
                enrolledCount: 1250,
                isEnrolled: true,
                reviews: 428,
                updatedAt: "2023-10-15T10:00:00Z",
                createdAt: "2023-08-01T08:30:00Z",
                authorCreator: "Apple Developer Education",
                estimatedDuration: "2 hours",
                rating: 4.8,
                difficultyLevel: .intermediate,
                contentType: .tutorial,
                resourcePlatform: .apple,
                tags: ["Swift", "iOS", "SwiftUI", "Programming"],
                isBookmarked: true,
                progress: 0.35,
                publishedDate: Date().addingTimeInterval(-5184000) // 60 days ago
            ),
            
            LegacyLearningResource(
                id: "2",
                title: "Machine Learning Fundamentals",
                description: "An introduction to the core concepts of machine learning, including supervised and unsupervised learning, neural networks, and practical applications.",
                category: "Data Science",
                difficulty: "beginner",
                duration: 180,
                thumbnailUrl: "https://images.unsplash.com/photo-1522202226988-58777c7c33b5?q=80&w=1471&auto=format&fit=crop",
                imageUrl: nil,
                url: "https://example.com/ml-fundamentals",
                provider: "Coursera",
                providerName: "Stanford University",
                providerUrl: "https://www.coursera.org/learn/machine-learning",
                enrolledCount: 4375,
                isEnrolled: false,
                reviews: 952,
                updatedAt: "2023-11-01T14:20:00Z",
                createdAt: "2023-05-15T09:45:00Z",
                authorCreator: "Dr. Andrew Smith",
                estimatedDuration: "3 hours",
                rating: 4.9,
                difficultyLevel: .beginner,
                contentType: .course,
                resourcePlatform: .coursera,
                tags: ["Machine Learning", "AI", "Data Science", "Python"],
                isBookmarked: false,
                progress: nil,
                publishedDate: Date().addingTimeInterval(-7776000) // 90 days ago
            ),
            
            LegacyLearningResource(
                id: "3",
                title: "Responsive Web Design Mastery",
                description: "Master the art of responsive web design to create websites that look great on any device, from phones to desktops.",
                category: "Web Development",
                difficulty: "intermediate",
                duration: 90,
                thumbnailUrl: "https://images.unsplash.com/photo-1547658719-da2b51169166?q=80&w=1528&auto=format&fit=crop",
                imageUrl: nil,
                url: "https://example.com/responsive-web-design",
                provider: "YouTube",
                providerName: "WebDev Academy",
                providerUrl: "https://www.youtube.com/webdev",
                enrolledCount: 2875,
                isEnrolled: true,
                reviews: 513,
                updatedAt: "2023-10-28T11:15:00Z",
                createdAt: "2023-07-20T13:30:00Z",
                authorCreator: "Sarah Johnson",
                estimatedDuration: "1.5 hours",
                rating: 4.7,
                difficultyLevel: .intermediate,
                contentType: .video,
                resourcePlatform: .youtube,
                tags: ["CSS", "HTML", "Web Development", "Responsive Design"],
                isBookmarked: true,
                progress: 0.85,
                publishedDate: Date().addingTimeInterval(-3456000) // 40 days ago
            ),
            
            LegacyLearningResource(
                id: "4",
                title: "Introduction to Quantum Computing",
                description: "An accessible introduction to the fascinating world of quantum computing, explaining qubits, superposition, and quantum algorithms.",
                category: "Computer Science",
                difficulty: "advanced",
                duration: 150,
                thumbnailUrl: "https://images.unsplash.com/photo-1563841930606-67e2bce48b78?q=80&w=1374&auto=format&fit=crop",
                imageUrl: nil,
                url: "https://example.com/quantum-computing",
                provider: "edX",
                providerName: "MIT",
                providerUrl: "https://www.edx.org/learn/quantum-computing",
                enrolledCount: 1045,
                isEnrolled: false,
                reviews: 215,
                updatedAt: "2023-11-05T16:40:00Z",
                createdAt: "2023-09-10T10:20:00Z",
                authorCreator: "Prof. Richard Feynman",
                estimatedDuration: "2.5 hours",
                rating: 4.9,
                difficultyLevel: .advanced,
                contentType: .course,
                resourcePlatform: .edx,
                tags: ["Quantum Computing", "Physics", "Computer Science", "Algorithms"],
                isBookmarked: false,
                progress: nil,
                publishedDate: Date().addingTimeInterval(-2592000) // 30 days ago
            ),
            
            LegacyLearningResource(
                id: "5",
                title: "The Complete Guide to UX Research",
                description: "Learn how to conduct effective user research to inform your design decisions and create better user experiences.",
                category: "Design",
                difficulty: "beginner",
                duration: 105,
                thumbnailUrl: "https://images.unsplash.com/photo-1633419461186-7d40a38105ec?q=80&w=1470&auto=format&fit=crop",
                imageUrl: nil,
                url: "https://example.com/ux-research",
                provider: "Udemy",
                providerName: "Design Academy",
                providerUrl: "https://www.udemy.com/course/ux-research",
                enrolledCount: 3125,
                isEnrolled: true,
                reviews: 648,
                updatedAt: "2023-10-20T09:50:00Z",
                createdAt: "2023-06-15T11:25:00Z",
                authorCreator: "Emma Williams",
                estimatedDuration: "1.75 hours",
                rating: 4.6,
                difficultyLevel: .beginner,
                contentType: .course,
                resourcePlatform: .udemy,
                tags: ["UX Design", "Research", "User Testing", "Design"],
                isBookmarked: false,
                progress: 0.2,
                publishedDate: Date().addingTimeInterval(-4320000) // 50 days ago
            )
        ]
    }
}

// Compatibility computed property so legacy views using `sourcePlatform` continue working
extension LegacyLearningResource {
    var sourcePlatform: ResourcePlatform { resourcePlatform ?? .other }
}
