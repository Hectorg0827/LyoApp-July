import Foundation
import UIKit

// MARK: - Stories API Service for Google Cloud Run Backend

@MainActor
class StoriesAPIService: ObservableObject {
    static let shared = StoriesAPIService()
    
    @Published var isLoading = false
    @Published var error: StoriesError?
    
    private let baseURL: String
    private var authToken: String?
    
    private init() {
        self.baseURL = APIConfig.baseURL
        self.authToken = AuthenticationService.shared.currentToken
    }
    
    // MARK: - API Endpoints
    
    /// Fetch all stories from backend
    /// GET /api/v1/stories
    func fetchStories() async throws -> [StoryContent] {
        guard let url = URL(string: "\(baseURL)/api/v1/stories") else {
            throw StoriesError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthHeader(token: authToken)
        request.timeoutInterval = APIConfig.requestTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StoriesError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StoriesError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let storiesResponse = try JSONDecoder().decode(StoriesResponse.self, from: data)
        return storiesResponse.stories
    }
    
    /// Fetch stories for a specific user
    /// GET /api/v1/stories/user/:userId
    func fetchUserStories(userId: UUID) async throws -> [StoryContent] {
        guard let url = URL(string: "\(baseURL)/api/v1/stories/user/\(userId.uuidString)") else {
            throw StoriesError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthHeader(token: authToken)
        request.timeoutInterval = APIConfig.requestTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StoriesError.invalidResponse
        }
        
        let storiesResponse = try JSONDecoder().decode(StoriesResponse.self, from: data)
        return storiesResponse.stories
    }
    
    /// Create and upload a new story
    /// POST /api/v1/stories
    func createStory(segments: [StorySegment]) async throws -> StoryContent {
        guard let url = URL(string: "\(baseURL)/api/v1/stories") else {
            throw StoriesError.invalidURL
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Upload media files first
        var uploadedSegments: [StorySegment] = []
        
        for segment in segments {
            if segment.type == .photo || segment.type == .video {
                // Upload media and get URL
                if let mediaURL = segment.mediaURL {
                    let uploadedURL = try await uploadMedia(fileURL: mediaURL, type: segment.type)
                    
                    var updatedSegment = segment
                    updatedSegment = StorySegment(
                        id: segment.id,
                        type: segment.type,
                        mediaURL: uploadedURL,
                        backgroundColor: segment.backgroundColor,
                        duration: segment.duration,
                        text: segment.text,
                        textColor: segment.textColor
                    )
                    uploadedSegments.append(updatedSegment)
                }
            } else {
                uploadedSegments.append(segment)
            }
        }
        
        // Create story request
        let createRequest = CreateStoryRequest(segments: uploadedSegments)
        let jsonData = try JSONEncoder().encode(createRequest)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addAuthHeader(token: authToken)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = APIConfig.uploadTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StoriesError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw StoriesError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let storyResponse = try JSONDecoder().decode(StoryResponse.self, from: data)
        return storyResponse.story
    }
    
    /// Upload media file (photo/video) to backend
    /// POST /api/v1/stories/upload
    private func uploadMedia(fileURL: URL, type: StorySegmentType) async throws -> URL {
        guard let url = URL(string: "\(baseURL)/api/v1/stories/upload") else {
            throw StoriesError.invalidURL
        }
        
        let fileData = try Data(contentsOf: fileURL)
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addAuthHeader(token: authToken)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConfig.uploadTimeout
        
        // Create multipart body
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(type == .photo ? "image/jpeg" : "video/mp4")\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(type.rawValue)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StoriesError.uploadFailed
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
        return uploadResponse.url
    }
    
    /// Mark a story as viewed
    /// POST /api/v1/stories/:storyId/view
    func markStoryAsViewed(storyId: UUID) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/stories/\(storyId.uuidString)/view") else {
            throw StoriesError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addAuthHeader(token: authToken)
        request.timeoutInterval = APIConfig.requestTimeout
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StoriesError.viewUpdateFailed
        }
    }
    
    /// Add reaction to a story
    /// POST /api/v1/stories/:storyId/reactions
    func addReaction(storyId: UUID, emoji: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/stories/\(storyId.uuidString)/reactions") else {
            throw StoriesError.invalidURL
        }
        
        let reactionRequest = ReactionRequest(emoji: emoji)
        let jsonData = try JSONEncoder().encode(reactionRequest)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addAuthHeader(token: authToken)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = APIConfig.requestTimeout
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StoriesError.reactionFailed
        }
    }
    
    /// Reply to a story via DM
    /// POST /api/v1/stories/:storyId/reply
    func replyToStory(storyId: UUID, message: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/stories/\(storyId.uuidString)/reply") else {
            throw StoriesError.invalidURL
        }
        
        let replyRequest = ReplyRequest(message: message)
        let jsonData = try JSONEncoder().encode(replyRequest)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addAuthHeader(token: authToken)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = APIConfig.requestTimeout
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StoriesError.replyFailed
        }
    }
    
    /// Get story analytics (view count, viewers)
    /// GET /api/v1/stories/:storyId/analytics
    func getStoryAnalytics(storyId: UUID) async throws -> StoryAnalytics {
        guard let url = URL(string: "\(baseURL)/api/v1/stories/\(storyId.uuidString)/analytics") else {
            throw StoriesError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthHeader(token: authToken)
        request.timeoutInterval = APIConfig.requestTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StoriesError.analyticsFailed
        }
        
        let analytics = try JSONDecoder().decode(StoryAnalytics.self, from: data)
        return analytics
    }
    
    /// Delete a story
    /// DELETE /api/v1/stories/:storyId
    func deleteStory(storyId: UUID) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/stories/\(storyId.uuidString)") else {
            throw StoriesError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addAuthHeader(token: authToken)
        request.timeoutInterval = APIConfig.requestTimeout
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw StoriesError.deleteFailed
        }
    }
    
    /// Add story to highlights
    /// POST /api/v1/stories/:storyId/highlight
    func addToHighlights(storyId: UUID, highlightName: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/stories/\(storyId.uuidString)/highlight") else {
            throw StoriesError.invalidURL
        }
        
        let highlightRequest = HighlightRequest(name: highlightName)
        let jsonData = try JSONEncoder().encode(highlightRequest)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addAuthHeader(token: authToken)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = APIConfig.requestTimeout
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StoriesError.highlightFailed
        }
    }
}

// MARK: - API Request/Response Models

struct StoriesResponse: Codable {
    let stories: [StoryContent]
    let count: Int
}

struct StoryResponse: Codable {
    let story: StoryContent
    let message: String?
}

struct CreateStoryRequest: Codable {
    let segments: [StorySegment]
}

struct UploadResponse: Codable {
    let url: URL
    let filename: String
}

struct ReactionRequest: Codable {
    let emoji: String
}

struct ReplyRequest: Codable {
    let message: String
}

struct HighlightRequest: Codable {
    let name: String
}

struct StoryAnalytics: Codable {
    let storyId: UUID
    let viewCount: Int
    let viewers: [StoryViewer]
    let reactions: [StoryReaction]
    let replyCount: Int
}

struct StoryViewer: Codable {
    let userId: UUID
    let username: String
    let viewedAt: Date
}

struct StoryReaction: Codable {
    let userId: UUID
    let username: String
    let emoji: String
    let reactedAt: Date
}

// MARK: - Errors

enum StoriesError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case uploadFailed
    case viewUpdateFailed
    case reactionFailed
    case replyFailed
    case analyticsFailed
    case deleteFailed
    case highlightFailed
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .uploadFailed:
            return "Failed to upload media"
        case .viewUpdateFailed:
            return "Failed to mark story as viewed"
        case .reactionFailed:
            return "Failed to add reaction"
        case .replyFailed:
            return "Failed to send reply"
        case .analyticsFailed:
            return "Failed to fetch analytics"
        case .deleteFailed:
            return "Failed to delete story"
        case .highlightFailed:
            return "Failed to add to highlights"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - URLRequest Extension for Auth Header

extension URLRequest {
    mutating func addAuthHeader(token: String?) {
        if let token = token {
            setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}

// MARK: - Authentication Service (Stub - should use your existing one)

class AuthenticationService {
    static let shared = AuthenticationService()
    
    var currentToken: String? {
        // Get from UserDefaults or Keychain
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    private init() {}
}
