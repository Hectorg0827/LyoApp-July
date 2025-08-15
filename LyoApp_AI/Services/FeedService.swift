import Foundation
import Combine

// MARK: - Feed Service Protocol
protocol FeedServiceProtocol {
    func getFeed(page: Int, limit: Int) async throws -> FeedResponse
    func createPost(_ post: CreatePostRequest) async throws -> Post
    func likePost(postId: String) async throws
    func unlikePost(postId: String) async throws
    func commentOnPost(postId: String, comment: CreateCommentRequest) async throws -> Comment
    func reportPost(postId: String, reason: String) async throws
    func deletePost(postId: String) async throws
    func getPostDetails(postId: String) async throws -> PostDetails
}

// MARK: - Feed Models
struct FeedResponse: Codable {
    let posts: [Post]
    let pagination: Pagination
    let hasMore: Bool
    
    private enum CodingKeys: String, CodingKey {
        case posts
        case pagination
        case hasMore = "has_more"
    }
}

struct Pagination: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let itemsPerPage: Int
    
    private enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case totalItems = "total_items"
        case itemsPerPage = "items_per_page"
    }
}

struct Post: Codable, Identifiable {
    let id: String
    let author: User
    let content: PostContent
    let engagement: PostEngagement
    let createdAt: Date
    let updatedAt: Date?
    let tags: [String]
    let visibility: PostVisibility
    
    private enum CodingKeys: String, CodingKey {
        case id
        case author
        case content
        case engagement
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case tags
        case visibility
    }
}

struct PostContent: Codable {
    let text: String?
    let media: [MediaAttachment]
    let linkedCourse: Course?
    let type: PostType
    
    private enum CodingKeys: String, CodingKey {
        case text
        case media
        case linkedCourse = "linked_course"
        case type
    }
}

struct MediaAttachment: Codable {
    let mediaId: String
    let url: String
    let type: MediaAttachmentType
    let metadata: MediaMetadata?
    
    private enum CodingKeys: String, CodingKey {
        case mediaId = "media_id"
        case url
        case type
        case metadata
    }
}

enum MediaAttachmentType: String, Codable {
    case image
    case video
    case document
}

struct PostEngagement: Codable {
    let likes: Int
    let comments: Int
    let shares: Int
    let isLikedByCurrentUser: Bool
    
    private enum CodingKeys: String, CodingKey {
        case likes
        case comments
        case shares
        case isLikedByCurrentUser = "is_liked_by_current_user"
    }
}

enum PostType: String, Codable {
    case text
    case media
    case courseShare = "course_share"
    case achievement
    case question
}

enum PostVisibility: String, Codable {
    case public
    case followers
    case friends
    case private
}

struct CreatePostRequest: Codable {
    let content: String?
    let mediaIds: [String]?
    let courseId: String?
    let type: PostType
    let visibility: PostVisibility
    let tags: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case content
        case mediaIds = "media_ids"
        case courseId = "course_id"
        case type
        case visibility
        case tags
    }
}

struct Comment: Codable, Identifiable {
    let id: String
    let author: User
    let content: String
    let createdAt: Date
    let likes: Int
    let isLikedByCurrentUser: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id
        case author
        case content
        case createdAt = "created_at"
        case likes
        case isLikedByCurrentUser = "is_liked_by_current_user"
    }
}

struct CreateCommentRequest: Codable {
    let content: String
}

struct PostDetails: Codable {
    let post: Post
    let comments: [Comment]
    let relatedPosts: [Post]
    
    private enum CodingKeys: String, CodingKey {
        case post
        case comments
        case relatedPosts = "related_posts"
    }
}

// MARK: - Live Feed Service
class LiveFeedService: FeedServiceProtocol {
    private let httpClient: HTTPClientProtocol
    private let baseURL: URL
    
    init(httpClient: HTTPClientProtocol, baseURL: String = "http://localhost:8002") {
        self.httpClient = httpClient
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL")
        }
        self.baseURL = url
    }
    
    func getFeed(page: Int = 1, limit: Int = 20) async throws -> FeedResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("/api/v1/feed"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        let request = HTTPRequest.get(url: components.url!)
        return try await httpClient.request(request, responseType: FeedResponse.self)
    }
    
    func createPost(_ post: CreatePostRequest) async throws -> Post {
        let url = baseURL.appendingPathComponent("/api/v1/posts")
        let request = try HTTPRequest.post(url: url, body: post)
        
        return try await httpClient.request(request, responseType: Post.self)
    }
    
    func likePost(postId: String) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/posts/\(postId)/like")
        let request = HTTPRequest(method: .POST, url: url)
        
        try await httpClient.request(request)
    }
    
    func unlikePost(postId: String) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/posts/\(postId)/like")
        let request = HTTPRequest(method: .DELETE, url: url)
        
        try await httpClient.request(request)
    }
    
    func commentOnPost(postId: String, comment: CreateCommentRequest) async throws -> Comment {
        let url = baseURL.appendingPathComponent("/api/v1/posts/\(postId)/comments")
        let request = try HTTPRequest.post(url: url, body: comment)
        
        return try await httpClient.request(request, responseType: Comment.self)
    }
    
    func reportPost(postId: String, reason: String) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/posts/\(postId)/report")
        let reportRequest = ReportRequest(reason: reason)
        let request = try HTTPRequest.post(url: url, body: reportRequest)
        
        try await httpClient.request(request)
    }
    
    func deletePost(postId: String) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/posts/\(postId)")
        let request = HTTPRequest.delete(url: url)
        
        try await httpClient.request(request)
    }
    
    func getPostDetails(postId: String) async throws -> PostDetails {
        let url = baseURL.appendingPathComponent("/api/v1/posts/\(postId)")
        let request = HTTPRequest.get(url: url)
        
        return try await httpClient.request(request, responseType: PostDetails.self)
    }
}

// MARK: - Report Request
struct ReportRequest: Codable {
    let reason: String
}

// MARK: - Mock Feed Service
class MockFeedService: FeedServiceProtocol {
    var shouldFail = false
    var loadDelay: Double = 1.0
    
    private var mockPosts: [Post] = []
    
    init() {
        generateMockPosts()
    }
    
    func getFeed(page: Int = 1, limit: Int = 20) async throws -> FeedResponse {
        try await Task.sleep(nanoseconds: UInt64(loadDelay * 1_000_000_000))
        
        if shouldFail {
            throw NSError(domain: "FeedError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load feed"])
        }
        
        let startIndex = (page - 1) * limit
        let endIndex = min(startIndex + limit, mockPosts.count)
        let posts = Array(mockPosts[startIndex..<endIndex])
        
        return FeedResponse(
            posts: posts,
            pagination: Pagination(
                currentPage: page,
                totalPages: (mockPosts.count + limit - 1) / limit,
                totalItems: mockPosts.count,
                itemsPerPage: limit
            ),
            hasMore: endIndex < mockPosts.count
        )
    }
    
    func createPost(_ post: CreatePostRequest) async throws -> Post {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        if shouldFail {
            throw NSError(domain: "FeedError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to create post"])
        }
        
        let newPost = Post(
            id: UUID().uuidString,
            author: User(
                id: "current_user",
                email: "current@example.com",
                displayName: "Current User",
                profilePictureURL: nil,
                isEmailVerified: true,
                preferences: UserPreferences(
                    learningGoals: ["iOS Development"],
                    difficultyLevel: .intermediate,
                    studyReminders: true,
                    contentLanguage: "en"
                ),
                stats: UserStats(totalPoints: 150, streak: 5, completedCourses: 3),
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            content: PostContent(
                text: post.content,
                media: [],
                linkedCourse: nil,
                type: post.type
            ),
            engagement: PostEngagement(
                likes: 0,
                comments: 0,
                shares: 0,
                isLikedByCurrentUser: false
            ),
            createdAt: Date(),
            updatedAt: nil,
            tags: post.tags ?? [],
            visibility: post.visibility
        )
        
        mockPosts.insert(newPost, at: 0)
        return newPost
    }
    
    func likePost(postId: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Mock liked post: \(postId)")
    }
    
    func unlikePost(postId: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Mock unliked post: \(postId)")
    }
    
    func commentOnPost(postId: String, comment: CreateCommentRequest) async throws -> Comment {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        if shouldFail {
            throw NSError(domain: "FeedError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to add comment"])
        }
        
        return Comment(
            id: UUID().uuidString,
            author: User(
                id: "current_user",
                email: "current@example.com",
                displayName: "Current User",
                profilePictureURL: nil,
                isEmailVerified: true,
                preferences: UserPreferences(
                    learningGoals: ["iOS Development"],
                    difficultyLevel: .intermediate,
                    studyReminders: true,
                    contentLanguage: "en"
                ),
                stats: UserStats(totalPoints: 150, streak: 5, completedCourses: 3),
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            content: comment.content,
            createdAt: Date(),
            likes: 0,
            isLikedByCurrentUser: false
        )
    }
    
    func reportPost(postId: String, reason: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Mock reported post: \(postId) for reason: \(reason)")
    }
    
    func deletePost(postId: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        mockPosts.removeAll { $0.id == postId }
        print("Mock deleted post: \(postId)")
    }
    
    func getPostDetails(postId: String) async throws -> PostDetails {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard let post = mockPosts.first(where: { $0.id == postId }) else {
            throw NSError(domain: "FeedError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
        }
        
        return PostDetails(
            post: post,
            comments: generateMockComments(),
            relatedPosts: Array(mockPosts.prefix(3))
        )
    }
    
    private func generateMockPosts() {
        for i in 1...50 {
            let post = Post(
                id: "mock_post_\(i)",
                author: User(
                    id: "user_\(i % 10)",
                    email: "user\(i % 10)@example.com",
                    displayName: "User \(i % 10)",
                    profilePictureURL: nil,
                    isEmailVerified: true,
                    preferences: UserPreferences(
                        learningGoals: ["iOS Development"],
                        difficultyLevel: .beginner,
                        studyReminders: true,
                        contentLanguage: "en"
                    ),
                    stats: UserStats(totalPoints: i * 10, streak: i % 7, completedCourses: i % 5),
                    createdAt: Date().addingTimeInterval(-TimeInterval(i * 3600)),
                    lastActiveAt: Date()
                ),
                content: PostContent(
                    text: "This is mock post \(i). Excited to share my learning progress!",
                    media: [],
                    linkedCourse: nil,
                    type: .text
                ),
                engagement: PostEngagement(
                    likes: Int.random(in: 0...100),
                    comments: Int.random(in: 0...20),
                    shares: Int.random(in: 0...10),
                    isLikedByCurrentUser: Bool.random()
                ),
                createdAt: Date().addingTimeInterval(-TimeInterval(i * 3600)),
                updatedAt: nil,
                tags: ["learning", "progress"],
                visibility: .public
            )
            mockPosts.append(post)
        }
    }
    
    private func generateMockComments() -> [Comment] {
        return (1...5).map { i in
            Comment(
                id: "comment_\(i)",
                author: User(
                    id: "commenter_\(i)",
                    email: "commenter\(i)@example.com",
                    displayName: "Commenter \(i)",
                    profilePictureURL: nil,
                    isEmailVerified: true,
                    preferences: UserPreferences(
                        learningGoals: ["iOS Development"],
                        difficultyLevel: .beginner,
                        studyReminders: true,
                        contentLanguage: "en"
                    ),
                    stats: UserStats(totalPoints: i * 20, streak: i, completedCourses: 1),
                    createdAt: Date(),
                    lastActiveAt: Date()
                ),
                content: "This is a mock comment \(i).",
                createdAt: Date().addingTimeInterval(-TimeInterval(i * 1800)),
                likes: Int.random(in: 0...10),
                isLikedByCurrentUser: Bool.random()
            )
        }
    }
}
