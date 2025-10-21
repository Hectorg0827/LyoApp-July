import Foundation
import Combine

// Note: Post and ClassroomCourse are defined in Models/Models.swift and Models/ClassroomModels.swift
// APIKeys is defined in Config/APIKeys.swift which uses APIEnvironment from Core/Networking/APIEnvironment.swift

// MARK: - Network Layer
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()

    private let session = URLSession.shared
    private var baseURL: URL {
        // Use the unified base URL from APIKeys (which wraps APIEnvironment)
        return URL(string: APIKeys.baseURL)!
    }
    
    private init() {}
    
    // MARK: - Generic Request Method
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = body
        }
        
        // Add authentication if available
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(T.self, from: data)
            
        } catch {
            throw NetworkError.networkError(error)
        }
    }
    
    // MARK: - Specific API Methods
    func fetchPosts() async throws -> [Post] {
        try await request(endpoint: "/posts", responseType: [Post].self)
    }
    
    func fetchUserProfile(userId: String) async throws -> User {
        try await request(endpoint: "/users/\(userId)", responseType: User.self)
    }
    
    func fetchCourses() async throws -> [ClassroomCourse] {
        try await request(endpoint: "/courses", responseType: [ClassroomCourse].self)
    }
    
    func sendAIMessage(_ message: String) async throws -> AIResponse {
        let requestBody = AIMessageNetworkRequest(message: message)
        let data = try JSONEncoder().encode(requestBody)
        
        return try await request(
            endpoint: "/ai/chat",
            method: .POST,
            body: data,
            responseType: AIResponse.self
        )
    }
    
    func uploadPost(_ post: PostCreateRequest) async throws -> Post {
        let data = try JSONEncoder().encode(post)
        return try await request(
            endpoint: "/posts",
            method: .POST,
            body: data,
            responseType: Post.self
        )
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Request/Response Models
struct AIMessageNetworkRequest: Codable {
    let message: String
    var timestamp: Date = Date()
}

struct AIResponse: Codable {
    let id: String
    let message: String
    let timestamp: Date
    let confidence: Double
    let suggestions: [String]?
}

struct PostCreateRequest: Codable {
    let content: String
    let imageURL: String?
    let courseId: String?
    let tags: [String]
}
