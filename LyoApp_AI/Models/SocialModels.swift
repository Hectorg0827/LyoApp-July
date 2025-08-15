import Foundation

// MARK: - Feed & Social Models
struct Post: Codable, Identifiable {
    let id: String
    let author: PostAuthor
    let content: PostContent
    let metrics: PostMetrics
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, author, content, metrics
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PostAuthor: Codable {
    let id: String
    let username: String
    let displayName: String
    let avatarURL: String?
    let isVerified: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, username, displayName = "display_name"
        case avatarURL = "avatar_url"
        case isVerified = "is_verified"
    }
}

struct PostContent: Codable {
    let text: String?
    let media: [MediaRef]
    let tags: [String]
    let mentions: [String]
    let location: PostLocation?
}

struct PostLocation: Codable {
    let name: String
    let latitude: Double?
    let longitude: Double?
}

struct PostMetrics: Codable {
    let likes: Int
    let comments: Int
    let shares: Int
    let views: Int
    let saves: Int
    
    // User's interaction status
    let userLiked: Bool
    let userSaved: Bool
    let userShared: Bool
    
    enum CodingKeys: String, CodingKey {
        case likes, comments, shares, views, saves
        case userLiked = "user_liked"
        case userSaved = "user_saved" 
        case userShared = "user_shared"
    }
}

struct FeedItem: Codable, Identifiable {
    let id: String
    let post: Post
    let reason: [FeedReason]
    let rankingScore: Double?
    let rankerChoice: String?
    
    enum CodingKeys: String, CodingKey {
        case id, post, reason
        case rankingScore = "ranking_score"
        case rankerChoice = "ranker_choice"
    }
}

struct FeedReason: Codable {
    let type: FeedReasonType
    let description: String
}

enum FeedReasonType: String, Codable {
    case following = "following"
    case liked = "liked_by_following"
    case trending = "trending"
    case recommended = "recommended"
    case similar = "similar_interests"
}

struct Comment: Codable, Identifiable {
    let id: String
    let postId: String
    let author: PostAuthor
    let text: String
    let parentId: String?
    let replies: [Comment]?
    let metrics: CommentMetrics
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, author, text, replies, metrics
        case postId = "post_id"
        case parentId = "parent_id"
        case createdAt = "created_at"
    }
}

struct CommentMetrics: Codable {
    let likes: Int
    let replies: Int
    let userLiked: Bool
    
    enum CodingKeys: String, CodingKey {
        case likes, replies
        case userLiked = "user_liked"
    }
}

enum ReactionType: String, Codable, CaseIterable {
    case like, love, haha, wow, sad, angry
    
    var emoji: String {
        switch self {
        case .like: return "👍"
        case .love: return "❤️"
        case .haha: return "😂"
        case .wow: return "😮"
        case .sad: return "😢"
        case .angry: return "😡"
        }
    }
}

struct CreatePost: Codable {
    let text: String?
    let mediaIds: [String]
    let tags: [String]
    let mentions: [String]
    let location: PostLocation?
    
    enum CodingKeys: String, CodingKey {
        case text, tags, mentions, location
        case mediaIds = "media_ids"
    }
}

// MARK: - Story Models
struct Story: Codable, Identifiable {
    let id: String
    let author: PostAuthor
    let media: MediaRef
    let caption: String?
    let viewers: [String]
    let createdAt: Date
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, author, media, caption, viewers
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

struct StoryReel: Codable, Identifiable {
    let id: String
    let author: PostAuthor
    let stories: [Story]
    let hasUnread: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, author, stories
        case hasUnread = "has_unread"
    }
}

// MARK: - Messaging Models
struct Chat: Codable, Identifiable {
    let id: String
    let type: ChatType
    let members: [PostAuthor]
    let lastMessage: Message?
    let unreadCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, members, unreadCount
        case lastMessage = "last_message"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum ChatType: String, Codable {
    case direct, group
}

struct Message: Codable, Identifiable {
    let id: String
    let chatId: String
    let sender: PostAuthor
    let content: MessageContent
    let status: MessageStatus
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, sender, content, status
        case chatId = "chat_id"
        case createdAt = "created_at"
    }
}

struct MessageContent: Codable {
    let text: String?
    let media: MediaRef?
    let replyTo: String?
    
    enum CodingKeys: String, CodingKey {
        case text, media
        case replyTo = "reply_to"
    }
}

enum MessageStatus: String, Codable {
    case sending, sent, delivered, read, failed
}

enum MessageEvent: Codable {
    case message(Message)
    case typing(TypingEvent)
    case read(ReadEvent)
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
}

struct TypingEvent: Codable {
    let userId: String
    let isTyping: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case isTyping = "is_typing"
    }
}

struct ReadEvent: Codable {
    let userId: String
    let messageId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case messageId = "message_id"
    }
}

// MARK: - Search Models
struct SearchResults: Codable {
    let query: String
    let posts: [Post]
    let profiles: [Profile]
    let tags: [HashtagResult]
    let hasMore: Bool
    let cursor: String?
    
    enum CodingKeys: String, CodingKey {
        case query, posts, profiles, tags
        case hasMore = "has_more"
        case cursor
    }
}

struct HashtagResult: Codable, Identifiable {
    let id: String
    let tag: String
    let postCount: Int
    let trending: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, tag, trending
        case postCount = "post_count"
    }
}

struct TrendingResults: Codable {
    let hashtags: [HashtagResult]
    let topics: [String]
    let recommendedUsers: [Profile]
    
    enum CodingKeys: String, CodingKey {
        case hashtags, topics
        case recommendedUsers = "recommended_users"
    }
}

enum SearchType: String, Codable, CaseIterable {
    case all, posts, profiles, tags
}

// MARK: - Notification Models
struct AppNotification: Codable, Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let data: [String: String]
    let read: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, body, data, read
        case createdAt = "created_at"
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case like, comment, follow, mention, message, course, tutor
    
    var icon: String {
        switch self {
        case .like: return "heart.fill"
        case .comment: return "bubble.left"
        case .follow: return "person.badge.plus"
        case .mention: return "at"
        case .message: return "message"
        case .course: return "graduationcap"
        case .tutor: return "brain.head.profile"
        }
    }
}
