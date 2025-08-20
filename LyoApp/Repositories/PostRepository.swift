import Foundation
import CoreData

// MARK: - Post Repository
@MainActor
class PostRepository: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    
    @Published var posts: [PostEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Post Operations
    func loadPosts(limit: Int = 50) async {
        isLoading = true
        defer { isLoading = false }
        
        posts = coreDataManager.fetchPosts(limit: limit)
    }
    
    func createPost(
        authorId: String,
        content: String,
        imageURLs: [String] = [],
        videoURL: String? = nil,
        tags: [String] = [],
        location: String? = nil
    ) async -> Result<PostEntity, Error> {
        isLoading = true
        defer { isLoading = false }
        
        let post = coreDataManager.createPost(
            authorId: authorId,
            content: content,
            imageURLs: imageURLs,
            videoURL: videoURL,
            tags: tags,
            location: location
        )
        
        await loadPosts()
        return .success(post)
    }
    
    func likePost(_ postId: String, by userId: String) async {
        guard let post = posts.first(where: { $0.id == postId }) else { return }
    // CoreData schema doesn't track per-user like state; increment likes count
    post.likes += 1
        coreDataManager.save()
    }
    
    func sharePost(_ postId: String, by userId: String) async {
        guard posts.first(where: { $0.id == postId }) != nil else { return }
    // No shareCount in current schema; this is a no-op placeholder to persist any changes if needed
        coreDataManager.save()
    }
    
    func convertToFeedItem(_ post: PostEntity) -> FeedItem? {
    // PostEntity properties are non-optional in current schema
    let id = post.id
    let authorId = post.authorId
    let content = post.content
        
        // Create a basic user for the feed item (in a real app, fetch from UserRepository)
        let author = User(
            username: "user_\(authorId)",
            email: "\(authorId)@example.com",
            fullName: "User \(authorId)"
        )
        
        let engagement = EngagementMetrics(
            likes: Int(post.likes),
            comments: Int(post.comments),
            shares: 0,
            saves: 0,
            isLiked: false,
            isSaved: false
        )

        // Current schema lacks media URLs; default to article content
        let articleContent = ArticleContent(
            title: content,
            excerpt: String(content.prefix(100)),
            content: content,
            heroImageURL: nil,
            readTime: 300.0
        )
        let contentType: FeedContentType = .article(articleContent)
        
        return FeedItem(
            id: UUID(uuidString: id) ?? UUID(),
            creator: author,
            contentType: contentType,
            timestamp: post.createdAt,
            engagement: engagement,
            duration: 120.0
        )
    }
}

// MARK: - Post Repository Errors
enum PostRepositoryError: LocalizedError {
    case postNotFound
    case creationFailed
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .postNotFound:
            return "Post not found"
        case .creationFailed:
            return "Failed to create post"
        case .updateFailed:
            return "Failed to update post"
        }
    }
}
