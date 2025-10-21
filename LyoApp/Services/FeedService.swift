import Foundation
import SwiftUI
import Combine

// MARK: - Feed Service (Real Backend Integration)
/// Handles all feed-related backend operations with no mock data fallback
@MainActor
final class FeedService: ObservableObject {
    static let shared = FeedService()
    
    // MARK: - Published Properties
    @Published var feedItems: [FeedItem] = []
    @Published var isLoading = false
    @Published var error: FeedServiceError?
    @Published var hasMoreContent = true
    
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private var currentPage = 1
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    
    // Backend endpoints
    private let feedEndpoint = "/api/v1/feed"
    private let likeEndpoint = "/api/v1/posts/{postId}/like"
    private let commentEndpoint = "/api/v1/posts/{postId}/comments"
    private let shareEndpoint = "/api/v1/posts/{postId}/share"
    private let saveEndpoint = "/api/v1/posts/{postId}/save"
    
    // MARK: - Initialization
    private init() {
        print("🔷 FeedService: Initialized with REAL backend only")
    }
    
    // MARK: - Feed Loading
    /// Load initial feed or refresh
    func loadFeed(refresh: Bool = false) async {
        // Check authentication first
        guard TokenStore.shared.loadTokens() != nil else {
            error = .unauthorized
            print("❌ FeedService: User not authenticated")
            return
        }
        
        guard !isLoading else { return }
        
        if refresh {
            currentPage = 1
            hasMoreContent = true
        }
        
        guard hasMoreContent else { return }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            print("🔷 FeedService: Loading page \(currentPage) from backend...")
            
            let response: FeedResponse = try await apiClient.request(
                endpoint: feedEndpoint,
                method: .GET,
                queryParams: [
                    "page": "\(currentPage)",
                    "limit": "\(pageSize)",
                    "include": "user,engagement,media"
                ]
            )
            
            let newItems = response.posts.map { convertToFeedItem($0) }
            
            if refresh {
                feedItems = newItems
            } else {
                feedItems.append(contentsOf: newItems)
            }
            
            hasMoreContent = newItems.count >= pageSize
            currentPage += 1
            
            print("✅ FeedService: Loaded \(newItems.count) items (Total: \(feedItems.count))")
            
        } catch let apiError as APIClientError {
            error = .apiError(apiError)
            print("❌ FeedService: API error - \(apiError.errorDescription ?? "Unknown")")
        } catch {
            self.error = .unknown(error.localizedDescription)
            print("❌ FeedService: Unknown error - \(error)")
        }
    }
    
    // MARK: - Post Interactions
    /// Toggle like on a post
    func toggleLike(postId: UUID) async -> Bool {
        guard let index = feedItems.firstIndex(where: { $0.id == postId }) else {
            return false
        }
        
        let wasLiked = feedItems[index].engagement.isLiked
        
        // Optimistic update
        feedItems[index].engagement.isLiked.toggle()
        feedItems[index].engagement.likes += wasLiked ? -1 : 1
        
        do {
            let endpoint = likeEndpoint.replacingOccurrences(of: "{postId}", with: postId.uuidString)
            let response: LikeResponse = try await apiClient.request(
                endpoint: endpoint,
                method: .POST
            )
            
            // Update with server response
            feedItems[index].engagement.isLiked = response.isLiked
            feedItems[index].engagement.likes = response.likesCount
            
            print("✅ FeedService: Post \(postId) like toggled - \(response.isLiked)")
            return true
            
        } catch {
            // Revert optimistic update on error
            feedItems[index].engagement.isLiked = wasLiked
            feedItems[index].engagement.likes += wasLiked ? 1 : -1
            print("❌ FeedService: Failed to toggle like - \(error)")
            return false
        }
    }
    
    /// Add comment to a post
    func addComment(postId: UUID, text: String) async -> Bool {
        do {
            let endpoint = commentEndpoint.replacingOccurrences(of: "{postId}", with: postId.uuidString)
            let response: CommentResponse = try await apiClient.request(
                endpoint: endpoint,
                method: .POST,
                body: ["text": text]
            )
            
            // Update comment count
            if let index = feedItems.firstIndex(where: { $0.id == postId }) {
                feedItems[index].engagement.comments += 1
            }
            
            print("✅ FeedService: Comment added to post \(postId)")
            return true
            
        } catch {
            print("❌ FeedService: Failed to add comment - \(error)")
            return false
        }
    }
    
    /// Share a post
    func sharePost(postId: UUID) async -> Bool {
        do {
            let endpoint = shareEndpoint.replacingOccurrences(of: "{postId}", with: postId.uuidString)
            let response: ShareResponse = try await apiClient.request(
                endpoint: endpoint,
                method: .POST
            )
            
            // Update share count
            if let index = feedItems.firstIndex(where: { $0.id == postId }) {
                feedItems[index].engagement.shares = response.sharesCount
            }
            
            print("✅ FeedService: Post \(postId) shared")
            return true
            
        } catch {
            print("❌ FeedService: Failed to share post - \(error)")
            return false
        }
    }
    
    /// Save/unsave a post
    func toggleSave(postId: UUID) async -> Bool {
        guard let index = feedItems.firstIndex(where: { $0.id == postId }) else {
            return false
        }
        
        let wasSaved = feedItems[index].engagement.isSaved
        
        // Optimistic update
        feedItems[index].engagement.isSaved.toggle()
        feedItems[index].engagement.saves += wasSaved ? -1 : 1
        
        do {
            let endpoint = saveEndpoint.replacingOccurrences(of: "{postId}", with: postId.uuidString)
            let response: SaveResponse = try await apiClient.request(
                endpoint: endpoint,
                method: wasSaved ? .DELETE : .POST
            )
            
            // Update with server response
            feedItems[index].engagement.isSaved = response.isSaved
            feedItems[index].engagement.saves = response.savesCount
            
            print("✅ FeedService: Post \(postId) save toggled - \(response.isSaved)")
            return true
            
        } catch {
            // Revert optimistic update
            feedItems[index].engagement.isSaved = wasSaved
            feedItems[index].engagement.saves += wasSaved ? 1 : -1
            print("❌ FeedService: Failed to toggle save - \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func convertToFeedItem(_ apiPost: APIFeedPost) -> FeedItem {
        let user = User(
            id: UUID(uuidString: apiPost.userId) ?? UUID(),
            username: apiPost.user.username,
            email: apiPost.user.email,
            fullName: apiPost.user.displayName ?? apiPost.user.username,
            bio: apiPost.user.bio,
            profileImageURL: apiPost.user.avatarURL,
            followers: apiPost.user.followersCount ?? 0,
            following: apiPost.user.followingCount ?? 0,
            isVerified: apiPost.user.isVerified ?? false,
            joinedDate: ISO8601DateFormatter().date(from: apiPost.user.createdAt ?? "") ?? Date()
        )
        
        let engagement = EngagementMetrics(
            likes: apiPost.likesCount,
            comments: apiPost.commentsCount,
            shares: apiPost.sharesCount,
            saves: apiPost.savesCount ?? 0,
            isLiked: apiPost.isLiked,
            isSaved: apiPost.isSaved ?? false
        )
        
        let contentType = buildContentType(from: apiPost)
        
        let timestamp = ISO8601DateFormatter().date(from: apiPost.createdAt) ?? Date()
        
        return FeedItem(
            id: UUID(uuidString: apiPost.id) ?? UUID(),
            creator: user,
            contentType: contentType,
            timestamp: timestamp,
            engagement: engagement,
            duration: contentType.duration
        )
    }
    
    private func buildContentType(from apiPost: APIFeedPost) -> FeedContentType {
        if let videoURL = apiPost.videoURL {
            return .video(VideoContent(
                url: videoURL,
                thumbnailURL: apiPost.thumbnailURL ?? URL(string: "https://via.placeholder.com/400x600")!,
                title: apiPost.title ?? "",
                description: apiPost.content,
                quality: .hd,
                duration: apiPost.duration ?? 180
            ))
        } else if let imageURLs = apiPost.imageURLs, !imageURLs.isEmpty {
            return .article(ArticleContent(
                title: apiPost.title ?? String(apiPost.content.prefix(60)),
                excerpt: String(apiPost.content.prefix(150)),
                content: apiPost.content,
                heroImageURL: imageURLs.first,
                readTime: apiPost.readTime ?? Double(apiPost.content.count / 200 * 60)
            ))
        } else {
            return .article(ArticleContent(
                title: apiPost.title ?? String(apiPost.content.prefix(60)),
                excerpt: String(apiPost.content.prefix(150)),
                content: apiPost.content,
                heroImageURL: nil,
                readTime: apiPost.readTime ?? Double(apiPost.content.count / 200 * 60)
            ))
        }
    }
}

// MARK: - Service Errors
enum FeedServiceError: LocalizedError {
    case apiError(APIClientError)
    case invalidData
    case unauthorized
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .apiError(let error):
            return error.errorDescription
        case .invalidData:
            return "Invalid data received from server"
        case .unauthorized:
            return "Please log in to view your feed"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - API Response Models
struct FeedResponse: Codable {
    let posts: [APIFeedPost]
    let pagination: PaginationInfo
}

struct APIFeedPost: Codable {
    let id: String
    let userId: String
    let user: APIFeedUser
    let content: String
    let title: String?
    let videoURL: URL?
    let thumbnailURL: URL?
    let imageURLs: [URL]?
    let duration: TimeInterval?
    let readTime: TimeInterval?
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let savesCount: Int?
    let isLiked: Bool
    let isSaved: Bool?
    let createdAt: String
    let updatedAt: String
}

struct APIFeedUser: Codable {
    let id: String
    let username: String
    let email: String
    let displayName: String?
    let bio: String?
    let avatarURL: URL?
    let followersCount: Int?
    let followingCount: Int?
    let isVerified: Bool?
    let createdAt: String?
}

struct PaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let hasNext: Bool
}

struct LikeResponse: Codable {
    let isLiked: Bool
    let likesCount: Int
}

struct CommentResponse: Codable {
    let id: String
    let text: String
    let userId: String
    let createdAt: String
}

struct ShareResponse: Codable {
    let sharesCount: Int
}

struct SaveResponse: Codable {
    let isSaved: Bool
    let savesCount: Int
}
