import Foundation

// MARK: - Base Response Models

// Renamed to avoid duplicate/ambiguous type issues across the project.
struct APIEmptyResponse: Codable {
    init() {}
}

struct APIEmptyRequest: Codable {
    init() {}
}

struct ProgressUpdateResponse: Codable {
    let success: Bool
    let resourceId: String
    let progress: Double
    let timeSpent: Int
    let message: String
}

struct ProgressUpdateRequest: Codable {
    let resourceId: String
    let progressType: String
    let timeSpent: Int
}

struct LikePostResponse: Codable {
    let success: Bool
    let postId: String
    let isLiked: Bool
    let likesCount: Int
}

struct CommentResponse: Codable {
    let success: Bool
    let commentId: String
    let postId: String
    let content: String
    let createdAt: String
}

struct ShareResponse: Codable {
    let success: Bool
    let postId: String
    let shareCount: Int
}

struct CreatePostResponse: Codable {
    let success: Bool
    let postId: String
    let content: String
    let createdAt: String
}

struct UserProfileResponse: Codable {
    let success: Bool
    let user: UserProfile
}

struct FollowResponse: Codable {
    let success: Bool
    let userId: String
    let isFollowing: Bool
    let followersCount: Int
}

struct SearchUsersResponse: Codable {
    let success: Bool
    let users: [UserProfile]
    let hasMore: Bool
    let nextPage: Int?
}

struct SearchContentResponse: Codable {
    let success: Bool
    let posts: [FeedPost]
    let resources: [APILearningResource]
    let hasMore: Bool
    let nextPage: Int?
}

// MARK: - Request Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let username: String
    let fullName: String
}

struct CommentRequest: Codable {
    let postId: String
    let content: String
}

struct CreatePostRequest: Codable {
    let content: String
    let mediaUrls: [String]
}

struct UserProfile: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let fullName: String
    let bio: String?
    let profileImageUrl: String?
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let isFollowing: Bool?
    let isFollower: Bool?
    let createdAt: String
}

struct UpdateUserProfileRequest: Codable {
    let username: String?
    let email: String?
    let fullName: String?
    let bio: String?
    let profileImageUrl: String?
}

// MARK: - Auth Refresh Models

// Public request model for /auth/refresh that supports snake_case field name commonly used by backends.
struct RefreshTokenRequest: Codable {
    let refreshToken: String
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// Flexible response model that tolerates various backend field names.
struct TokenRefreshResponse: Codable {
    let accessToken: String?
    let token: String?
    let access_token: String?
    let refreshToken: String?
    let refresh_token: String?
    let expiresIn: Int?
    let expires_in: Int?
    let user: ResponseAPIUser?

    var actualAccessToken: String {
        token ?? accessToken ?? access_token ?? ""
    }
    var actualRefreshToken: String? {
        refreshToken ?? refresh_token
    }
}

// MARK: - AI API Models
struct AIGenerationRequest: Codable {
    let prompt: String
    let maxTokens: Int
    let temperature: Double?
    let model: String?
    
    init(prompt: String, maxTokens: Int, temperature: Double? = nil, model: String? = nil) {
        self.prompt = prompt
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.model = model
    }
}

struct AIGenerationResponse: Codable {
    let generatedText: String
    let tokensUsed: Int
    let model: String
    let finishReason: String
    let usage: TokenUsage?
    
    init(generatedText: String, tokensUsed: Int, model: String, finishReason: String, usage: TokenUsage? = nil) {
        self.generatedText = generatedText
        self.tokensUsed = tokensUsed
        self.model = model
        self.finishReason = finishReason
        self.usage = usage
    }
}

struct AIStatusResponse: Codable {
    let status: String
    let model: String
    let capabilities: [String]
    let isAvailable: Bool
    let lastUpdated: String?
    
    init(status: String, model: String, capabilities: [String], isAvailable: Bool, lastUpdated: String? = nil) {
        self.status = status
        self.model = model
        self.capabilities = capabilities
        self.isAvailable = isAvailable
        self.lastUpdated = lastUpdated
    }
}

struct TokenUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}

struct APIErrorResponse: Codable {
    let error: String
    let message: String?
    let code: Int?
}

// MARK: - Legacy API Models (for backward compatibility)

struct LoginResponse: Codable {
    let user: ResponseAPIUser
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    
    // Backend compatibility - backend returns 'token' instead of 'accessToken'
    let token: String?
    
    // Use token if available, otherwise fall back to accessToken
    var actualAccessToken: String {
        return token ?? accessToken ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case user, accessToken, refreshToken, token
        case expiresIn = "expires_in"
    }
}

// Create a namespace to avoid type conflicts
enum APINamespace {
    struct APIUser: Codable {
        let id: String
        let email: String
        let username: String?
        let fullName: String?
        let avatar: String?
        let xp: Int?
        let level: Int?
        let streak: Int?
        let badges: [String]?
        let bio: String?
        let createdAt: String?
        
        // Computed properties for compatibility
        var name: String { fullName ?? username ?? "User" }
        var avatarUrl: String? { avatar }
        
        enum CodingKeys: String, CodingKey {
            case id, email, username, fullName, avatar, xp, level, streak, badges, bio, createdAt
        }
        
        /// Convert API user to domain User model
        func toDomainUser() -> User {
            return User(
                id: UUID(uuidString: id) ?? UUID(),
                username: username ?? email.components(separatedBy: "@").first ?? "user",
                email: email,
                fullName: name,
                bio: bio,
                profileImageURL: avatarUrl.flatMap { URL(string: $0) },
                followers: 0,
                following: 0,
                posts: 0,
                isVerified: false,
                joinedAt: createdAt.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date(),
                lastActiveAt: Date(),
                experience: xp ?? 0,
                level: level ?? 1
            )
        }
    }
}

// Type alias for backward compatibility
typealias ResponseAPIUser = APINamespace.APIUser

// Add to the namespace to avoid type conflicts
extension APINamespace {
    struct LoginRequest: Codable {
        let email: String
        let password: String
    }
}

// Type alias for backward compatibility
typealias ResponseLoginRequest = APINamespace.LoginRequest

struct ErrorResponse: Codable {
    let detail: String?
    let message: String?
    
    init(detail: String? = nil, message: String? = nil) {
        self.detail = detail
        self.message = message
    }
}

// MARK: - Source Platform for Search
enum SourcePlatform: String, CaseIterable, Codable {
    case youtube = "youtube"
    case coursera = "coursera"
    case edx = "edx"
    case udemy = "udemy"
    case khanAcademy = "khan_academy"
    case podcasts = "podcasts"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .youtube: return "YouTube"
        case .coursera: return "Coursera"
        case .edx: return "edX"
        case .udemy: return "Udemy"
        case .khanAcademy: return "Khan Academy"
        case .podcasts: return "Podcasts"
        case .all: return "All Sources"
        }
    }
}

// MARK: - Feed API Models

struct FeedResponse: Codable {
    let posts: [FeedPost]
    let hasMore: Bool
    let nextPage: Int?
    
    // Backend compatibility - backend returns 'data' instead of 'posts'
    let data: [FeedPost]?
    let pagination: PaginationInfo?
    
    // Standard initializer for mock data
    init(posts: [FeedPost], hasMore: Bool, nextPage: Int?) {
        self.posts = posts
        self.hasMore = hasMore
        self.nextPage = nextPage
        self.data = nil
        self.pagination = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case posts, hasMore, nextPage
        case data, pagination
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode posts first, if not available use data from backend
        if let posts = try? container.decode([FeedPost].self, forKey: .posts) {
            self.posts = posts
        } else if let data = try? container.decode([FeedPost].self, forKey: .data) {
            self.posts = data
        } else {
            self.posts = []
        }
        
        // Handle pagination info
        if let pagination = try? container.decode(PaginationInfo.self, forKey: .pagination) {
            self.hasMore = pagination.hasMore
            self.nextPage = pagination.hasMore ? pagination.currentPage + 1 : nil
        } else {
            self.hasMore = (try? container.decode(Bool.self, forKey: .hasMore)) ?? false
            self.nextPage = try? container.decode(Int.self, forKey: .nextPage)
        }
        
        self.data = try? container.decode([FeedPost].self, forKey: .data)
        self.pagination = try? container.decode(PaginationInfo.self, forKey: .pagination)
    }
}

struct PaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalPosts: Int
    let hasMore: Bool
}

// MARK: - Backend Feed Response Models
struct BackendFeedPost: Codable {
    let id: String
    let user: BackendFeedUser
    let content: String
    let mediaUrl: String?
    let mediaType: String?
    let timestamp: String
    let likes: Int
    let comments: Int
    let shares: Int
    let isLiked: Bool
    let tags: [String]?
    
    func toFeedPost() -> FeedPost {
        let imageURLs: [URL]?
        let videoURL: URL?
        
        if let mediaUrl = mediaUrl, !mediaUrl.isEmpty, let url = URL(string: mediaUrl) {
            if mediaType == "video" {
                imageURLs = nil
                videoURL = url
            } else {
                imageURLs = [url]
                videoURL = nil
            }
        } else {
            imageURLs = nil
            videoURL = nil
        }
        
        return FeedPost(
            id: id,
            userId: user.id,
            username: user.username,
            userAvatar: user.avatar.flatMap { URL(string: $0) },
            content: content,
            imageURLs: imageURLs,
            videoURL: videoURL,
            likesCount: likes,
            commentsCount: comments,
            sharesCount: shares,
            isLiked: isLiked,
            isBookmarked: false,
            createdAt: timestamp,
            tags: tags
        )
    }
}

struct BackendFeedUser: Codable {
    let id: String
    let username: String
    let avatar: String?
    let isVerified: Bool?
}

struct BackendFeedResponse: Codable {
    let success: Bool?
    let data: [BackendFeedPost]
    let pagination: PaginationInfo
    
    func toFeedResponse() -> FeedResponse {
        return FeedResponse(
            posts: data.map { $0.toFeedPost() },
            hasMore: pagination.hasMore,
            nextPage: pagination.hasMore ? pagination.currentPage + 1 : nil
        )
    }
}


struct PostResponse: Codable {
    let post: FeedPost
    let success: Bool
}

struct CreateStoryRequest: Codable {
    let mediaUrl: String
    let mediaType: String // "image" or "video"
    let duration: Int? // in seconds for videos
    let text: String?
}

struct StoryResponse: Codable {
    let story: StoryAPI
    let success: Bool
}

struct StoryAPI: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let userAvatar: String?
    let mediaUrl: String
    let mediaType: String
    let text: String?
    let createdAt: String
    let expiresAt: String
}

struct LikeResponse: Codable {
    let isLiked: Bool
    let likesCount: Int
}


// MARK: - Learning Resources API Models

struct APILearningResource: Identifiable, Codable {
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
    let rating: Double?
    
    // Convert APILearningResource to LearningResource (simplified)
    func toLearningResource() -> LearningResource {
        return LearningResource(
            id: self.id,
            title: self.title,
            description: self.description,
            category: self.category ?? "General",
            difficulty: self.difficulty ?? "Beginner",
            duration: self.duration,
            thumbnailUrl: self.thumbnailUrl,
            imageUrl: self.imageUrl,
            url: self.url,
            provider: self.provider,
            providerName: self.providerName,
            providerUrl: self.providerUrl,
            enrolledCount: self.enrolledCount,
            isEnrolled: self.isEnrolled ?? false,
            reviews: self.reviews,
            updatedAt: nil,
            createdAt: nil,
            authorCreator: self.provider,
            estimatedDuration: self.duration != nil ? "\(self.duration!) min" : nil,
            rating: self.rating,
            difficultyLevel: .beginner,
            contentType: .course,
            resourcePlatform: nil,
            tags: [],
            isBookmarked: false,
            progress: 0.0,
            publishedDate: nil
        )
    }
}

struct LearningResourcesResponse: Codable {
    let resources: [APILearningResource]
    let categories: [String]
    let hasMore: Bool
    let nextPage: Int?
}

struct CoursesResponse: Codable {
    let success: Bool
    let data: [BackendCourse]
    let totalCourses: Int
    let page: Int
    let limit: Int
    
    func toLearningResourcesResponse() -> LearningResourcesResponse {
        let resources = data.map { $0.toAPILearningResource() }
        return LearningResourcesResponse(
            resources: resources,
            categories: ["Programming", "Data Science", "Design", "Business"], // Default categories
            hasMore: page * limit < totalCourses,
            nextPage: page * limit < totalCourses ? page + 1 : nil
        )
    }
}

struct BackendCourse: Codable {
    let id: String
    let title: String
    let description: String
    let instructor: String
    let duration: String
    let level: String
    let rating: Double
    let studentsCount: Int
    let price: Double
    let thumbnail: String
    let tags: [String]
    let lessons: [APILesson]
    let progress: Int
    
    func toAPILearningResource() -> APILearningResource {
        return APILearningResource(
            id: id,
            title: title,
            description: description,
            category: tags.first ?? "Programming",
            difficulty: level,
            duration: parseDuration(duration),
            thumbnailUrl: thumbnail,
            imageUrl: thumbnail, // Use thumbnail as imageUrl
            url: nil, // No URL available
            provider: "LyoApp",
            providerName: "LyoApp",
            providerUrl: nil, // No provider URL available
            enrolledCount: studentsCount,
            isEnrolled: false, // Default to not enrolled
            reviews: nil, // No reviews count available
            rating: rating
        )
    }
    
    private func parseDuration(_ duration: String) -> Int {
        // Parse "12 hours" -> 720 minutes, "8 hours" -> 480 minutes, etc.
        let components = duration.split(separator: " ")
        if components.count >= 2, let hours = Double(components[0]) {
            return Int(hours * 60) // Convert hours to minutes
        }
        return 60 // Default 1 hour
    }
}

struct APILesson: Codable {
    let id: String
    let title: String
    let duration: String
    let completed: Bool
}

struct CourseDetailsResponse: Codable {
    let course: CourseDetails
}

struct CourseDetails: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let longDescription: String?
    let category: String
    let difficulty: String
    let duration: Int? // in minutes
    let thumbnailUrl: String?
    let providerName: String
    let providerUrl: String?
    let lessons: [LessonAPI]
    let tags: [String]
    let rating: Double?
    let enrolledCount: Int
    let isEnrolled: Bool
    let progress: APICourseProgress?
    let createdAt: String
}

struct LessonAPI: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let duration: Int? // in minutes
    let orderIndex: Int
    let videoUrl: String?
    let materials: [LessonMaterial]
    let isCompleted: Bool
}

struct LessonMaterial: Codable, Identifiable {
    let id: String
    let title: String
    let type: String // "pdf", "link", "video", "quiz"
    let url: String?
    let content: String?
}

// NOTE: CourseProgress is defined in ClassroomModels.swift (canonical)
// Renamed to avoid ambiguity
struct APICourseProgress: Codable {
    let courseId: String
    let completedLessons: [String]
    let progressPercentage: Double
    let lastAccessedAt: String
}

struct EnrollmentResponse: Codable {
    let isEnrolled: Bool
    let enrollmentDate: String
}

struct ProgressTrackingRequest: Codable {
    let courseId: String
    let lessonId: String?
    let actionType: String // "start", "complete", "pause"
    let timeSpent: Int? // in seconds
}

struct ProgressResponse: Codable {
    let success: Bool
    let progress: APICourseProgress
}

// MARK: - Search API Models

enum SearchType: String, Codable, CaseIterable {
    case users = "users"
    case posts = "posts"
    case courses = "courses"
    case all = "all"
}

struct SearchResponse: Codable {
    let users: [UserProfile]?
    let posts: [FeedPost]?
    let courses: [LearningResource]?
    let hasMore: Bool
    let nextPage: Int?
    let totalResults: Int
}

// MARK: - AI Avatar API Models

public struct CourseOutlineResponse: Codable {
    let course: CourseOutline?
    let success: Bool
}

struct AIAvatarMessageRequest: Codable {
    let message: String
    let conversationId: String?
    let context: AIContext?
}

struct AIContext: Codable {
    let currentCourse: String?
    let userLevel: String?
    let preferences: [String: String]?
}

// MARK: - AI Response Models (using domain AIMessage from Models.swift)

public struct AIMessageResponse: Codable {
    let message: AIMessage
    let conversationId: String
}

public struct AIConversationResponse: Codable {
    let messages: [AIMessage]
    let conversationId: String
    let hasMore: Bool
}

// MARK: - Chat/Messenger API Models

public struct ChatHistoryResponse: Codable {
    let messages: [AIMessage]
    let hasMore: Bool
    let nextPage: Int?
}

struct SendMessageRequest: Codable {
    let chatId: String
    let content: String
    let messageType: String
    let mediaUrl: String?
}

public struct MessageResponse: Codable {
    let message: AIMessage
    let success: Bool
}

public struct ChatsListResponse: Codable {
    let conversations: [ChatConversation]
    let hasMore: Bool
    let nextPage: Int?
}

// MARK: - Study Groups API
struct StudyGroupAPI: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let subject: String
    let memberCount: Int
    let isPrivate: Bool
    let isMember: Bool
    let lastActivity: String
    let difficulty: String
    let tags: [String]
}

// MARK: - Authentication Request Models
struct AuthRequest: Codable {
    let email: String
    let password: String
}

// Removed duplicate RegisterRequest - using the one defined earlier

// Removed duplicate AI models - using the ones defined earlier
