import Foundation

// MARK: - Core Feed Models

/// Represents a single item in the user's feed.
struct FeedItem: Identifiable, Codable, Hashable {
    let id: UUID
    let creator: User
    let contentType: FeedContentType
    let timestamp: Date
    var engagement: EngagementMetrics
    
    // Conform to Hashable
    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Codable implementation
    enum CodingKeys: String, CodingKey {
        case id, creator, contentType, timestamp, engagement
    }
}

/// Defines the different types of content that can appear in a feed.
enum FeedContentType: Codable, Hashable {
    case video(VideoContent)
    case article(ArticleContent)
    case product(ProductContent)
    
    var duration: TimeInterval? {
        switch self {
        case .video(let videoContent):
            return videoContent.duration
        case .article(let articleContent):
            return articleContent.readTime
        case .product:
            return nil
        }
    }
}

/// Metrics for user engagement with a feed item.
struct EngagementMetrics: Codable, Hashable {
    var likes: Int
    var comments: Int
    var shares: Int
    var saves: Int
    var isLiked: Bool
    var isSaved: Bool
}

/// Represents video content in a feed item.
struct VideoContent: Codable, Hashable {
    let url: URL
    let thumbnailURL: URL
    let title: String
    let description: String
    let quality: VideoQuality
    let duration: TimeInterval
}

/// Represents article content in a feed item.
struct ArticleContent: Codable, Hashable {
    let title: String
    let excerpt: String
    let content: String
    let heroImageURL: URL?
    let readTime: TimeInterval
}

/// Represents product content in a feed item.
struct ProductContent: Codable, Hashable {
    let title: String
    let price: String
    let images: [URL]
    let model3DURL: URL?
    let description: String
}

/// Defines the quality of a video.
enum VideoQuality: String, Codable, CaseIterable, Hashable {
    case sd, hd, uhd
}
