import Foundation

// MARK: - Service Protocols

protocol AuthService {
    func loginWithApple(idToken: String, nonce: String) async throws -> AuthTokens
    func loginWithGoogle(idToken: String) async throws -> AuthTokens
    func loginWithMeta(accessToken: String) async throws -> AuthTokens
    func refresh() async throws -> AuthTokens
    func me() async throws -> Profile
    func logout() async throws
}

protocol MediaService {
    func presign(kind: MediaKind, mime: String) async throws -> Presign
    func commit(assetUrl: URL, kind: MediaKind, meta: MediaMeta) async throws -> MediaRef
}

protocol FeedService {
    func createPost(_ req: CreatePost) async throws -> String // Returns post ID
    func followingFeed(cursor: String?) async throws -> [FeedItem]
    func forYouFeed(cursor: String?) async throws -> [FeedItem]
    func react(postId: String, type: ReactionType) async throws
    func comment(postId: String, text: String, parent: String?) async throws -> String // Returns comment ID
    func deletePost(postId: String) async throws
    func reportPost(postId: String, reason: String) async throws
}

protocol StoryService {
    func createStory(mediaId: String, caption: String?) async throws -> String // Returns story ID
    func reel() async throws -> [StoryReel]
    func markViewed(storyId: String) async throws
}

protocol MessagingService {
    func createChat(members: [String], type: ChatType) async throws -> String // Returns chat ID
    func history(chatId: String, cursor: String?) async throws -> [Message]
    func send(chatId: String, text: String?, media: String?) async throws -> String // Returns message ID
    func connect(chatId: String) async throws -> AsyncStream<MessageEvent>
    func markRead(chatId: String, messageId: String) async throws
}

protocol NotificationService {
    func registerAPNs(token: Data) async throws
    func list(cursor: String?) async throws -> [AppNotification]
    func markRead(notificationId: String) async throws
    func markAllRead() async throws
}

protocol TutorService {
    func sendTurn(_ turn: TutorTurn) async throws -> [TutorEvent]
    func loadState(learnerId: String) async throws -> TutorContext
    func saveState(_ ctx: TutorContext) async throws
}

protocol CoursePlannerService {
    func draftPlan(goal: LearningGoal, profile: Profile) async throws -> CoursePlan
    func attachContent(planId: String) async throws -> CoursePlan
    func generatePractice(lessonId: String, profile: Profile) async throws -> [QuizItem]
    func recordResult(_ result: QuizResult) async throws -> CoursePlan
    func updateProgress(lessonId: String, status: LessonStatus) async throws
}

protocol SearchService {
    func search(query: String, type: SearchType, cursor: String?) async throws -> SearchResults
    func trending() async throws -> TrendingResults
}

protocol ProfileService {
    func follow(userId: String) async throws
    func unfollow(userId: String) async throws
    func block(userId: String) async throws
    func unblock(userId: String) async throws
    func updateProfile(_ profile: Profile) async throws -> Profile
    func getUserProfile(userId: String) async throws -> Profile
    func getFollowers(userId: String, cursor: String?) async throws -> [Profile]
    func getFollowing(userId: String, cursor: String?) async throws -> [Profile]
}

// MARK: - Error Types
enum APIError: Error, LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case validationError(String)
    case rateLimited
    case maintenance
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You need to log in to access this feature."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested content could not be found."
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse server response."
        case .validationError(let message):
            return "Invalid input: \(message)"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .maintenance:
            return "Service temporarily unavailable for maintenance."
        }
    }
}

// MARK: - HTTP Client
protocol HTTPClient {
    func request<T: Codable>(
        _ endpoint: APIEndpoint,
        body: Codable?,
        responseType: T.Type
    ) async throws -> T
    
    func upload(
        _ endpoint: APIEndpoint,
        data: Data,
        contentType: String
    ) async throws -> Data
}

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryParams: [String: String]
    
    init(
        path: String,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        queryParams: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParams = queryParams
    }
}

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}

// MARK: - WebSocket Client
protocol WebSocketClient {
    func connect(url: URL) async throws -> AsyncStream<WebSocketMessage>
    func send(_ message: WebSocketMessage) async throws
    func disconnect()
}

enum WebSocketMessage {
    case text(String)
    case data(Data)
}
