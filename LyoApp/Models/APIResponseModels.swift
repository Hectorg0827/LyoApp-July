import Foundation

// This file contains the response models that the APIClient uses to decode
// data from the backend. These are kept separate from the canonical app models
// to decouple the networking layer from the main application logic.

// MARK: - Generic & System Responses

struct SystemHealthResponse: Codable {
    let status: String
    let version: String
    let timestamp: Date
}

struct APIEmptyRequest: Codable {}

// MARK: - Authentication Responses

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let user: ResponseAPIUser
    
    var actualAccessToken: String {
        return accessToken
    }
}

struct TokenRefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    
    var actualAccessToken: String {
        return accessToken
    }
    
    var actualRefreshToken: String? {
        return refreshToken
    }
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let username: String
    let fullName: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

// MARK: - User Profile Responses

struct UserProfileResponse: Codable {
    let id: String
    let username: String
    let email: String
    let fullName: String
    let avatarUrl: String?
    let isVerified: Bool
}

struct UpdateUserProfileRequest: Codable {
    let fullName: String?
    let username: String?
    let bio: String?
}

struct FollowResponse: Codable {
    let isFollowing: Bool
    let followersCount: Int
}

// MARK: - Feed & Post Responses

struct BackendFeedResponse: Codable {
    let items: [FeedItemResponse]
    
    func toFeedResponse() -> FeedResponse {
        let posts = items.map { item in
            FeedItem(
                id: UUID(uuidString: item.id) ?? UUID(),
                creator: User(
                    id: item.author.id,
                    username: item.author.username,
                    email: "", // Not provided in this response
                    fullName: item.author.displayName,
                    avatarUrl: item.author.avatarUrl,
                    level: item.author.isVerified ? 5 : 1
                ),
                contentType: mapContentType(from: item),
                timestamp: ISO8601DateFormatter().date(from: item.createdAt) ?? Date(),
                engagement: EngagementMetrics(
                    likes: item.engagement.likes,
                    comments: item.engagement.comments,
                    shares: item.engagement.shares,
                    saves: item.engagement.saves,
                    isLiked: item.engagement.isLiked,
                    isSaved: item.engagement.isSaved
                )
            )
        }
        return FeedResponse(posts: posts)
    }
    
    private func mapContentType(from item: FeedItemResponse) -> FeedContentType {
        switch item.type.lowercased() {
        case "video":
            return .video(VideoContent(
                url: URL(string: item.mediaUrl ?? "")!,
                thumbnailURL: URL(string: item.thumbnailUrl ?? "")!,
                title: item.title,
                description: item.content ?? "",
                quality: .hd,
                duration: 120 // Placeholder
            ))
        default:
            return .article(ArticleContent(
                title: item.title,
                excerpt: item.content ?? "",
                content: item.content ?? "",
                heroImageURL: URL(string: item.thumbnailUrl ?? ""),
                readTime: 300 // Placeholder
            ))
        }
    }
}

struct FeedResponse: Codable {
    let posts: [FeedItem]
}

struct FeedItemResponse: Codable {
    let id: String
    let type: String
    let title: String
    let content: String?
    let mediaUrl: String?
    let thumbnailUrl: String?
    let createdAt: String
    let author: AuthorResponse
    let engagement: EngagementResponse
}

struct AuthorResponse: Codable {
    let id: String
    let username: String
    let displayName: String
    let avatarUrl: String?
    let isVerified: Bool
}

struct EngagementResponse: Codable {
    let likes: Int
    let comments: Int
    let shares: Int
    let saves: Int
    let isLiked: Bool
    let isSaved: Bool
}

struct CreatePostRequest: Codable {
    let content: String
    let mediaUrls: [String]
}

struct CreatePostResponse: Codable {
    let id: String
    let content: String
    let createdAt: String
}

struct LikePostResponse: Codable {
    let isLiked: Bool
    let likesCount: Int
}

struct CommentRequest: Codable {
    let postId: String
    let content: String
}

struct CommentResponse: Codable {
    let id: String
    let content: String
    let createdAt: String
}

struct ShareResponse: Codable {
    let sharesCount: Int
}

// MARK: - Learning & Courses Responses

struct CoursesResponse: Codable {
    let courses: [APILearningResource]
    
    func toLearningResourcesResponse() -> LearningResourcesResponse {
        let resources = courses.map { course in
            LearningResource(
                id: course.id,
                title: course.title,
                description: course.description,
                type: .course, // Assuming all are courses for now
                coverImage: URL(string: course.coverImage ?? "")
            )
        }
        return LearningResourcesResponse(resources: resources)
    }
}

struct LearningResourcesResponse {
    let resources: [LearningResource]
}

struct LearningResource: Identifiable {
    let id: String
    let title: String
    let description: String
    let type: ResourceType
    let coverImage: URL?
}

enum ResourceType: String, Codable {
    case course, article, video
}

struct EnrollmentResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Search Responses

struct SearchUsersResponse: Codable {
    let users: [ResponseAPIUser]
}

struct SearchContentResponse: Codable {
    let posts: [FeedItemResponse]
}

// MARK: - AI & Progress Responses

struct AIGenerationRequest: Codable {
    let prompt: String
    let maxTokens: Int
}

struct AIGenerationResponse: Codable {
    let text: String
}

struct AIStatusResponse: Codable {
    let status: String
}

struct ProgressUpdateRequest: Codable {
    let resourceId: String
    let progressType: String
    let timeSpent: Int
}

struct ProgressUpdateResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Backend-Specific Models (To be mapped to canonical models)

struct ResponseAPIUser: Codable {
    let id: String
    let username: String
    let email: String?
    let fullName: String
    let avatarUrl: String?
    let isVerified: Bool
}

struct APILearningResource: Codable {
    let id: String
    let title: String
    let description: String
    let coverImage: String?
}
