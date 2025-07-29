import SwiftUI
import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    var id: UUID
    var username: String
    var email: String
    var fullName: String
    var bio: String?
    var profileImageURL: String?
    var followers: Int
    var following: Int
    var posts: Int
    var badges: [UserBadge]
    var level: Int
    var experience: Int
    var joinDate: Date
    
    init(
        id: UUID = UUID(),
        username: String,
        email: String,
        fullName: String,
        bio: String? = nil,
        profileImageURL: String? = nil,
        followers: Int = 0,
        following: Int = 0,
        posts: Int = 0,
        badges: [UserBadge] = [],
        level: Int = 1,
        experience: Int = 0,
        joinDate: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.fullName = fullName
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.followers = followers
        self.following = following
        self.posts = posts
        self.badges = badges
        self.level = level
        self.experience = experience
        self.joinDate = joinDate
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, username, email, fullName, bio, profileImageURL
        case followers, following, posts, badges, level, experience
        case joinDate
    }
}

// MARK: - Post Model
struct Post: Codable, Identifiable {
    var id: UUID
    let author: User
    var content: String
    var imageURLs: [String]
    var videoURL: String?
    var likes: Int
    var comments: Int
    var shares: Int
    var isLiked: Bool
    var isBookmarked: Bool
    var createdAt: Date
    var tags: [String]
    var location: Location?
    
    init(
        id: UUID = UUID(),
        author: User,
        content: String,
        imageURLs: [String] = [],
        videoURL: String? = nil,
        likes: Int = 0,
        comments: Int = 0,
        shares: Int = 0,
        isLiked: Bool = false,
        isBookmarked: Bool = false,
        createdAt: Date = Date(),
        tags: [String] = [],
        location: Location? = nil
    ) {
        self.id = id
        self.author = author
        self.content = content
        self.imageURLs = imageURLs
        self.videoURL = videoURL
        self.likes = likes
        self.comments = comments
        self.shares = shares
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
        self.createdAt = createdAt
        self.tags = tags
        self.location = location
    }
}

// MARK: - Story Models
struct Story: Codable, Identifiable {
    var id: UUID = UUID()
    let author: User
    let mediaURL: String
    let mediaType: StoryMediaType
    var isViewed: Bool
    let createdAt: Date
    let expiresAt: Date
    
    enum StoryMediaType: String, Codable {
        case image, video
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }
}

// MARK: - Comment Model
struct Comment: Codable, Identifiable {
    let id: UUID
    let author: User
    let content: String
    let likes: Int
    let isLiked: Bool
    let createdAt: Date
    let replies: [Comment]?
}

// MARK: - Location Model
struct Location: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Badge Model
struct UserBadge: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let iconName: String
    let color: String
    let rarity: Rarity
    let earnedAt: Date?
    
    enum Rarity: String, Codable {
        case common, rare, epic, legendary
        
        var color: Color {
            switch self {
            case .common: return .gray
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .orange
            }
        }
    }
}

// MARK: - Course Model
struct Course: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let instructor: String
    let thumbnailURL: String
    let duration: TimeInterval
    let difficulty: Difficulty
    let category: String
    let lessons: [Lesson]
    var progress: Double
    var isEnrolled: Bool
    let rating: Double
    let studentsCount: Int
    
    enum Difficulty: String, Codable, CaseIterable {
        case beginner, intermediate, advanced
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .orange
            case .advanced: return .red
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        instructor: String,
        thumbnailURL: String,
        duration: TimeInterval,
        difficulty: Difficulty,
        category: String,
        lessons: [Lesson] = [],
        progress: Double = 0.0,
        isEnrolled: Bool = false,
        rating: Double = 0.0,
        studentsCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.instructor = instructor
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.difficulty = difficulty
        self.category = category
        self.lessons = lessons
        self.progress = progress
        self.isEnrolled = isEnrolled
        self.rating = rating
        self.studentsCount = studentsCount
    }
}

// MARK: - Lesson Model
struct Lesson: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let videoURL: String?
    let duration: TimeInterval
    let isCompleted: Bool
    let order: Int
    let resources: [Resource]
}

// MARK: - Resource Model
struct Resource: Codable, Identifiable {
    let id: UUID
    let title: String
    let type: ResourceType
    let url: String
    
    enum ResourceType: String, Codable {
        case pdf, video, link, quiz
    }
}

// MARK: - Chat Models
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let senderId: UUID
    let content: String
    let timestamp: Date
    let messageType: MessageType
    let isRead: Bool
    
    enum MessageType: String, Codable {
        case text, image, video, audio, file
    }
}

struct ChatConversation: Codable, Identifiable {
    let id: UUID
    let participants: [User]
    let lastMessage: ChatMessage?
    let unreadCount: Int
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Community Models
struct Community: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let memberCount: Int
    let isPrivate: Bool
    let category: String
    
    init(name: String, description: String, icon: String, memberCount: Int, isPrivate: Bool, category: String) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.icon = icon
        self.memberCount = memberCount
        self.isPrivate = isPrivate
        self.category = category
    }
    
    enum CodingKeys: String, CodingKey {
        case name, description, icon, memberCount, isPrivate, category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.icon = try container.decode(String.self, forKey: .icon)
        self.memberCount = try container.decode(Int.self, forKey: .memberCount)
        self.isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
        self.category = try container.decode(String.self, forKey: .category)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(icon, forKey: .icon)
        try container.encode(memberCount, forKey: .memberCount)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encode(category, forKey: .category)
    }
    
    // static let sampleCommunities = [
    //     // Sample communities moved to UserDataManager for real data management
    // ]
}

struct Discussion: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let author: User
    let community: Community
    let tags: [String]
    let likes: Int
    let replies: Int
    let createdAt: Date
    
    init(title: String, content: String, author: User, community: Community, tags: [String], likes: Int, replies: Int, createdAt: Date) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.author = author
        self.community = community
        self.tags = tags
        self.likes = likes
        self.replies = replies
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case title, content, author, community, tags, likes, replies, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.author = try container.decode(User.self, forKey: .author)
        self.community = try container.decode(Community.self, forKey: .community)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.likes = try container.decode(Int.self, forKey: .likes)
        self.replies = try container.decode(Int.self, forKey: .replies)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(author, forKey: .author)
        try container.encode(community, forKey: .community)
        try container.encode(tags, forKey: .tags)
        try container.encode(likes, forKey: .likes)
        try container.encode(replies, forKey: .replies)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    // static let sampleDiscussions = [
    //     // Sample discussions moved to UserDataManager for real data management
    // ]
}

struct CommunityEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let imageURL: String
    let date: Date
    let location: String
    let community: Community
    let attendeesCount: Int
    
    init(title: String, description: String, imageURL: String, date: Date, location: String, community: Community, attendeesCount: Int) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.date = date
        self.location = location
        self.community = community
        self.attendeesCount = attendeesCount
    }
    
    enum CodingKeys: String, CodingKey {
        case title, description, imageURL, date, location, community, attendeesCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.imageURL = try container.decode(String.self, forKey: .imageURL)
        self.date = try container.decode(Date.self, forKey: .date)
        self.location = try container.decode(String.self, forKey: .location)
        self.community = try container.decode(Community.self, forKey: .community)
        self.attendeesCount = try container.decode(Int.self, forKey: .attendeesCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(date, forKey: .date)
        try container.encode(location, forKey: .location)
        try container.encode(community, forKey: .community)
        try container.encode(attendeesCount, forKey: .attendeesCount)
    }
    
    // static let sampleEvents = [
    //     // Sample events moved to UserDataManager for real data management
    // ]
}

// MARK: - Helper Functions
func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}

// MARK: - Sample Data
// Note: Sample data has been removed to use real data from UserDataManager
// extension User {
//     // All sample users moved to UserDataManager for real data management
// }

// extension Post {
//     // Sample posts moved to UserDataManager for real data management
// }

// extension Story {
//     // Sample stories moved to UserDataManager for real data management
// }

// MARK: - Learning Models for AI-Powered Course Experience

struct LyoCourseChapter: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let keyPoints: [String]
    let exercises: [Exercise]
    let estimatedDuration: Int // in minutes
    let difficulty: ChapterDifficulty
    let concepts: [String]
    
    init(title: String, content: String, keyPoints: [String], exercises: [Exercise], estimatedDuration: Int, difficulty: ChapterDifficulty, concepts: [String]) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.keyPoints = keyPoints
        self.exercises = exercises
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
        self.concepts = concepts
    }
}

struct Exercise: Identifiable, Codable {
    let id: UUID
    let question: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String
    let type: ExerciseType
    
    init(question: String, options: [String], correctAnswer: Int, explanation: String, type: ExerciseType) {
        self.id = UUID()
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.type = type
    }
}

enum ExerciseType: String, Codable {
    case multipleChoice
    case trueFalse
    case fillInTheBlank
    case essay
}

enum ChapterDifficulty: String, Codable {
    case beginner
    case intermediate
    case advanced
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

// MARK: - Sample Course Content Generator
func generateCourseContent(for topic: String) -> [LyoCourseChapter] {
    return [
        LyoCourseChapter(
            title: "Introduction to \(topic)",
            content: "Welcome to your \(topic) learning journey! This chapter will introduce you to the fundamentals.",
            keyPoints: ["Basic concepts", "Key terminology", "Real-world applications"],
            exercises: sampleExercises,
            estimatedDuration: 15,
            difficulty: .beginner,
            concepts: ["Foundation", "Overview", "Basics"]
        ),
        LyoCourseChapter(
            title: "Core Concepts",
            content: "Now let's dive deeper into the core concepts of \(topic) and explore how they work together.",
            keyPoints: ["Advanced principles", "Interconnected systems", "Practical implementation"],
            exercises: sampleExercises,
            estimatedDuration: 25,
            difficulty: .intermediate,
            concepts: ["Theory", "Implementation", "Practice"]
        ),
        LyoCourseChapter(
            title: "Practical Applications",
            content: "Learn how to apply \(topic) concepts in real-world scenarios and projects.",
            keyPoints: ["Real-world examples", "Best practices", "Common pitfalls"],
            exercises: sampleExercises,
            estimatedDuration: 30,
            difficulty: .intermediate,
            concepts: ["Application", "Examples", "Practice"]
        ),
        LyoCourseChapter(
            title: "Advanced Techniques",
            content: "Master advanced techniques and become proficient in \(topic).",
            keyPoints: ["Expert strategies", "Optimization techniques", "Professional insights"],
            exercises: sampleExercises,
            estimatedDuration: 40,
            difficulty: .advanced,
            concepts: ["Mastery", "Optimization", "Expertise"]
        )
    ]
}

// MARK: - Sample Data for Learning
private let sampleExercises = [
    Exercise(
        question: "What is the primary benefit of this concept?",
        options: ["Performance", "Readability", "Maintainability", "All of the above"],
        correctAnswer: 3,
        explanation: "All these benefits are interconnected and important for good development practices.",
        type: .multipleChoice
    ),
    Exercise(
        question: "This statement is correct: Modern development practices emphasize clean code.",
        options: ["True", "False"],
        correctAnswer: 0,
        explanation: "Clean code is indeed a fundamental principle in modern software development.",
        type: .trueFalse
    )
]

let sampleChapter = LyoCourseChapter(
    title: "Getting Started with SwiftUI",
    content: """
    SwiftUI is Apple's innovative, simple way to build user interfaces across all Apple platforms with the power of Swift. Build user interfaces for any Apple device using just one set of tools and APIs.
    
    With a declarative Swift syntax that's easy to read and natural to write, SwiftUI works seamlessly with new Xcode design tools to keep your code and design perfectly in sync.
    """,
    keyPoints: [
        "Declarative syntax makes UI code more readable",
        "Cross-platform compatibility across Apple devices",
        "Real-time preview accelerates development",
        "Seamless integration with existing UIKit code"
    ],
    exercises: sampleExercises,
    estimatedDuration: 20,
    difficulty: .beginner,
    concepts: ["UI Framework", "Declarative Programming", "Cross-platform Development"]
)

// MARK: - Educational Content Models

// Enhanced Educational Video Model
struct EducationalVideo: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let thumbnailURL: String
    let videoURL: String
    let duration: TimeInterval
    let instructor: String
    let category: String
    let difficulty: Course.Difficulty
    let tags: [String]
    let rating: Double
    let viewCount: Int
    let isBookmarked: Bool
    let watchProgress: Double // 0.0 to 1.0
    let publishedDate: Date
    let language: String
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        thumbnailURL: String,
        videoURL: String,
        duration: TimeInterval,
        instructor: String,
        category: String,
        difficulty: Course.Difficulty = .beginner,
        tags: [String] = [],
        rating: Double = 0.0,
        viewCount: Int = 0,
        isBookmarked: Bool = false,
        watchProgress: Double = 0.0,
        publishedDate: Date = Date(),
        language: String = "English"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.duration = duration
        self.instructor = instructor
        self.category = category
        self.difficulty = difficulty
        self.tags = tags
        self.rating = rating
        self.viewCount = viewCount
        self.isBookmarked = isBookmarked
        self.watchProgress = watchProgress
        self.publishedDate = publishedDate
        self.language = language
    }
}

// Enhanced Ebook Model
struct Ebook: Codable, Identifiable {
    let id: UUID
    let title: String
    let author: String
    let description: String
    let coverImageURL: String
    let pdfURL: String
    let category: String
    let pages: Int
    let fileSize: String
    let rating: Double
    let downloadCount: Int
    let isBookmarked: Bool
    let readProgress: Double // 0.0 to 1.0
    let publishedDate: Date
    let language: String
    let tags: [String]
    
    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        description: String,
        coverImageURL: String,
        pdfURL: String,
        category: String,
        pages: Int,
        fileSize: String,
        rating: Double = 0.0,
        downloadCount: Int = 0,
        isBookmarked: Bool = false,
        readProgress: Double = 0.0,
        publishedDate: Date = Date(),
        language: String = "English",
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.description = description
        self.coverImageURL = coverImageURL
        self.pdfURL = pdfURL
        self.category = category
        self.pages = pages
        self.fileSize = fileSize
        self.rating = rating
        self.downloadCount = downloadCount
        self.isBookmarked = isBookmarked
        self.readProgress = readProgress
        self.publishedDate = publishedDate
        self.language = language
        self.tags = tags
    }
}

// Educational Content Type Enum
enum EducationalContentType: String, CaseIterable {
    case course = "course"
    case video = "video"
    case ebook = "ebook"
    case podcast = "podcast"
    case article = "article"
    
    var icon: String {
        switch self {
        case .course: return "graduationcap.fill"
        case .video: return "play.rectangle.fill"
        case .ebook: return "book.fill"
        case .podcast: return "mic.fill"
        case .article: return "doc.text.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .course: return "Courses"
        case .video: return "Videos"
        case .ebook: return "E-Books"
        case .podcast: return "Podcasts"
        case .article: return "Articles"
        }
    }
    
    var color: Color {
        switch self {
        case .course: return .blue
        case .video: return .red
        case .ebook: return .green
        case .podcast: return .purple
        case .article: return .orange
        }
    }
}

// MARK: - Podcast Episode Model
struct PodcastEpisode: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let audioURL: String
    let thumbnailURL: String
    let duration: TimeInterval
    let showName: String
    let publishedDate: Date
    let category: String
    let difficulty: Course.Difficulty
    let tags: [String]
    let transcript: String?
    let isBookmarked: Bool
    let playProgress: Double // 0.0 to 1.0
    let rating: Double
    
    init(id: UUID = UUID(),
         title: String,
         description: String,
         audioURL: String,
         thumbnailURL: String,
         duration: TimeInterval,
         showName: String,
         publishedDate: Date = Date(),
         category: String,
         difficulty: Course.Difficulty = .beginner,
         tags: [String] = [],
         transcript: String? = nil,
         isBookmarked: Bool = false,
         playProgress: Double = 0.0,
         rating: Double = 4.0) {
        self.id = id
        self.title = title
        self.description = description
        self.audioURL = audioURL
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.showName = showName
        self.publishedDate = publishedDate
        self.category = category
        self.difficulty = difficulty
        self.tags = tags
        self.transcript = transcript
        self.isBookmarked = isBookmarked
        self.playProgress = playProgress
        self.rating = rating
    }
}

// Learning Section Type for tabs
enum LearningSectionType: String, CaseIterable {
    case recentlyViewed = "recently_viewed"
    case favorites = "favorites"
    case watchLater = "watch_later"
    case downloaded = "downloaded"
    
    var displayName: String {
        switch self {
        case .recentlyViewed: return "Recently Viewed"
        case .favorites: return "Favorites"
        case .watchLater: return "Watch Later"
        case .downloaded: return "Downloaded"
        }
    }
    
    var icon: String {
        switch self {
        case .recentlyViewed: return "clock.fill"
        case .favorites: return "heart.fill"
        case .watchLater: return "bookmark.fill"
        case .downloaded: return "arrow.down.circle.fill"
        }
    }
}

// Sample data for testing
// extension EducationalVideo {
//     // Sample videos moved to UserDataManager for real data management
// }

// extension Ebook {
//     // Sample ebooks moved to UserDataManager for real data management
// }
