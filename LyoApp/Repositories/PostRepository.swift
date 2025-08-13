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
        
        if post.isLiked {
            post.likeCount -= 1
            post.isLiked = false
        } else {
            post.likeCount += 1
            post.isLiked = true
        }
        
        coreDataManager.save()
    }
    
    func sharePost(_ postId: String, by userId: String) async {
        guard let post = posts.first(where: { $0.id == postId }) else { return }
        post.shareCount += 1
        coreDataManager.save()
    }
    
    func convertToFeedItem(_ post: PostEntity) -> FeedItem? {
        guard let id = post.id,
              let authorId = post.authorId,
              let content = post.content else { return nil }
        
        // Create a basic user for the feed item (in a real app, fetch from UserRepository)
        let author = User(
            username: "user_\(authorId)",
            email: "\(authorId)@example.com",
            fullName: "User \(authorId)"
        )
        
        let engagement = EngagementMetrics(
            likes: Int(post.likeCount),
            comments: Int(post.commentCount),
            shares: Int(post.shareCount),
            saves: 0,
            isLiked: post.isLiked,
            isSaved: false
        )
        
        let contentType: FeedContentType
        if let videoURL = post.videoURL, let url = URL(string: videoURL) {
            let videoContent = VideoContent(
                url: url,
                thumbnailURL: URL(string: "https://example.com/thumbnail.jpg") ?? url,
                title: content,
                description: content,
                quality: .hd,
                duration: 120.0
            )
            contentType = .video(videoContent)
        } else {
            let articleContent = ArticleContent(
                title: content,
                excerpt: String(content.prefix(100)),
                content: content,
                heroImageURL: nil,
                readTime: 300.0
            )
            contentType = .article(articleContent)
        }
        
        return FeedItem(
            id: UUID(uuidString: id) ?? UUID(),
            creator: author,
            contentType: contentType,
            timestamp: post.timestamp ?? Date(),
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
