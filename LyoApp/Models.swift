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
    var badges: [Badge]
    var level: Int
    var experience: Int
    var joinDate: Date
    var isVerified: Bool
    
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
        badges: [Badge] = [],
        level: Int = 1,
        experience: Int = 0,
        joinDate: Date = Date(),
        isVerified: Bool = false
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
        self.isVerified = isVerified
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
struct Badge: Codable, Identifiable {
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
    let progress: Double
    let isEnrolled: Bool
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

// MARK: - Library Item Models
struct LibraryItem: Codable, Identifiable {
    var id: UUID = UUID()
    let title: String
    let type: LibraryItemType
    let thumbnailURL: String?
    let url: String
    let author: String
    let duration: TimeInterval?
    let savedAt: Date
    let progress: Double? // For courses and videos
    
    enum LibraryItemType: String, Codable, CaseIterable {
        case course = "course"
        case book = "book"
        case video = "video"
        case podcast = "podcast"
        
        var icon: String {
            switch self {
            case .course: return "graduationcap.fill"
            case .book: return "book.fill"
            case .video: return "play.rectangle.fill"
            case .podcast: return "mic.fill"
            }
        }
        
        var displayName: String {
            switch self {
            case .course: return "Courses"
            case .book: return "Books"
            case .video: return "Videos"
            case .podcast: return "Podcasts"
            }
        }
    }
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
    
    static let sampleCommunities = [
        Community(name: "SwiftUI Developers", description: "Everything about SwiftUI development", icon: "swift", memberCount: 2500, isPrivate: false, category: "Programming"),
        Community(name: "iOS Design", description: "Mobile app design and UX", icon: "paintbrush.fill", memberCount: 1800, isPrivate: false, category: "Design"),
        Community(name: "Tech Startups", description: "Startup founders and entrepreneurs", icon: "rocket.fill", memberCount: 3200, isPrivate: false, category: "Business"),
        Community(name: "AI & Machine Learning", description: "ML enthusiasts and researchers", icon: "brain.head.profile", memberCount: 4100, isPrivate: false, category: "Technology"),
        Community(name: "Photography", description: "Share your best shots", icon: "camera.fill", memberCount: 2800, isPrivate: false, category: "Art"),
        Community(name: "Digital Marketing", description: "Marketing strategies and tips", icon: "megaphone.fill", memberCount: 1900, isPrivate: false, category: "Business"),
        Community(name: "Music Production", description: "Producers and audio engineers", icon: "music.note", memberCount: 1500, isPrivate: false, category: "Music"),
        Community(name: "Game Development", description: "Indie game developers", icon: "gamecontroller.fill", memberCount: 2200, isPrivate: false, category: "Programming")
    ]
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
    
    static let sampleDiscussions = [
        Discussion(
            title: "Best practices for SwiftUI state management",
            content: "I've been working with SwiftUI for a while now and I'm curious about the best practices for managing state in complex applications. What are your thoughts on using @StateObject vs @ObservedObject?",
            author: User.sampleUsers[0],
            community: Community.sampleCommunities[0],
            tags: ["SwiftUI", "StateManagement", "iOS"],
            likes: 45,
            replies: 12,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        Discussion(
            title: "iOS 17 New Features Discussion",
            content: "What are your thoughts on the new iOS 17 features? Interactive widgets look amazing!",
            author: User.sampleUsers[1],
            community: Community.sampleCommunities[0],
            tags: ["iOS17", "Features", "Widgets"],
            likes: 78,
            replies: 23,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        Discussion(
            title: "Design System Implementation",
            content: "How do you approach building a scalable design system for a large iOS app?",
            author: User.sampleUsers[2],
            community: Community.sampleCommunities[1],
            tags: ["DesignSystem", "iOS", "UI"],
            likes: 34,
            replies: 8,
            createdAt: Date().addingTimeInterval(-10800)
        )
    ]
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
    
    static let sampleEvents = [
        CommunityEvent(
            title: "SwiftUI Workshop: Building Modern UIs",
            description: "Join us for a hands-on workshop where we'll build a complete SwiftUI app from scratch",
            imageURL: "https://picsum.photos/400/200",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            location: "Virtual Event",
            community: Community.sampleCommunities[0],
            attendeesCount: 145
        ),
        CommunityEvent(
            title: "Design System Meetup",
            description: "Learn how to create and maintain design systems for mobile applications",
            imageURL: "https://picsum.photos/400/200",
            date: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
            location: "San Francisco, CA",
            community: Community.sampleCommunities[1],
            attendeesCount: 89
        ),
        CommunityEvent(
            title: "AI in Mobile Apps Conference",
            description: "Exploring the future of AI integration in mobile applications",
            imageURL: "https://picsum.photos/400/200",
            date: Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date(),
            location: "New York, NY",
            community: Community.sampleCommunities[3],
            attendeesCount: 267
        )
    ]
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
extension User {
    static let sampleUsers = [
        User(username: "johndoe", email: "john@example.com", fullName: "John Doe", 
             bio: "Tech enthusiast and learner", followers: 1250, following: 850, posts: 42, isVerified: true),
        User(username: "janedoe", email: "jane@example.com", fullName: "Jane Doe", 
             bio: "Designer & Creative", followers: 980, following: 650, posts: 28),
        User(username: "alexsmith", email: "alex@example.com", fullName: "Alex Smith", 
             bio: "Student and aspiring developer", followers: 450, following: 320, posts: 15)
    ]
}

extension Post {
    static let samplePosts = [
        Post(author: User.sampleUsers[0], content: "Just completed my first SwiftUI course! 🎉 The declarative syntax is amazing and makes UI development so much more intuitive. Can't wait to build more apps!", 
             likes: 234, comments: 18, tags: ["SwiftUI", "iOS", "Learning"]),
        Post(author: User.sampleUsers[1], content: "Working on some new design concepts for mobile interfaces. Love how minimalism can create such powerful user experiences ✨", 
             likes: 156, comments: 12, tags: ["Design", "UX", "Mobile"]),
        Post(author: User.sampleUsers[2], content: "Had an amazing study session with Lyo today! The AI learning companion really helped me understand complex programming concepts through thoughtful questions. This platform is incredible! 🚀", 
             likes: 89, comments: 7, tags: ["AI", "Learning", "Programming"])
    ]
}

extension Story {
    static let sampleStories = [
        Story(
            author: User.sampleUsers[0],
            mediaURL: "https://picsum.photos/400/600?random=1",
            mediaType: .image,
            isViewed: false,
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            expiresAt: Date().addingTimeInterval(82800) // 23 hours from now
        ),
        Story(
            author: User.sampleUsers[1],
            mediaURL: "https://picsum.photos/400/600?random=2",
            mediaType: .video,
            isViewed: true,
            createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
            expiresAt: Date().addingTimeInterval(79200) // 22 hours from now
        ),
        Story(
            author: User.sampleUsers[2],
            mediaURL: "https://picsum.photos/400/600?random=3",
            mediaType: .image,
            isViewed: false,
            createdAt: Date().addingTimeInterval(-1800), // 30 minutes ago
            expiresAt: Date().addingTimeInterval(84600) // 23.5 hours from now
        )
    ]
}

extension LibraryItem {
    static let sampleLibraryItems = [
        LibraryItem(
            title: "Complete SwiftUI Course",
            type: .course,
            thumbnailURL: "https://picsum.photos/200/150?random=10",
            url: "course://swiftui-complete",
            author: "John Smith",
            duration: 18000, // 5 hours
            savedAt: Date().addingTimeInterval(-86400), // 1 day ago
            progress: 0.65
        ),
        LibraryItem(
            title: "Design Thinking Fundamentals",
            type: .book,
            thumbnailURL: "https://picsum.photos/200/150?random=11",
            url: "book://design-thinking",
            author: "Sarah Johnson",
            duration: nil,
            savedAt: Date().addingTimeInterval(-172800), // 2 days ago
            progress: 0.3
        ),
        LibraryItem(
            title: "iOS Architecture Patterns",
            type: .video,
            thumbnailURL: "https://picsum.photos/200/150?random=12",
            url: "video://ios-patterns",
            author: "Mike Chen",
            duration: 2700, // 45 minutes
            savedAt: Date().addingTimeInterval(-259200), // 3 days ago
            progress: 1.0
        ),
        LibraryItem(
            title: "Tech Talk: The Future of AI",
            type: .podcast,
            thumbnailURL: "https://picsum.photos/200/150?random=13",
            url: "podcast://ai-future",
            author: "AI Insights Podcast",
            duration: 3600, // 1 hour
            savedAt: Date().addingTimeInterval(-345600), // 4 days ago
            progress: 0.75
        )
    ]
}

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
