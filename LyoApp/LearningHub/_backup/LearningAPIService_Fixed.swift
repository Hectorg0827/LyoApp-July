import Foundation
import Combine
import SwiftUI

// MARK: - Learning HTTP Method
enum LearningHTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Learning API Service
/// Modular API service for Learning Hub with robust error handling
@MainActor
class LearningAPIService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = LearningAPIService()
    
    // MARK: - Configuration
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Published State
    @Published var isLoading = false
    @Published var lastError: LearningAPIError?
    @Published var isConnected = true
    
    // MARK: - Private Properties
    private var activeRequests: Set<UUID> = []
    
    // MARK: - Initialization
    private init() {
        #if DEBUG
        self.baseURL = "http://localhost:8000/api/v1/learning"
        #else
        self.baseURL = "https://api.lyoapp.com/api/v1/learning"
        #endif
        
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
        
        // Configure JSON decoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        print("✅ LearningAPIService initialized with baseURL: \(baseURL)")
    }
    
    // MARK: - Primary API Methods
    
    /// Fetch learning resources for a specific topic
    func fetchResources(for topic: String, limit: Int = 20, offset: Int = 0) async throws -> [LearningResource] {
        let requestId = UUID()
        print("🌐 NETWORK FETCH: Starting request \(requestId) for topic: '\(topic)'")
        
        activeRequests.insert(requestId)
        isLoading = true
        
        defer {
            activeRequests.remove(requestId)
            if activeRequests.isEmpty {
                isLoading = false
            }
        }
        
        do {
            let searchRequest = LearningSearchRequest(
                query: topic,
                limit: limit,
                offset: offset
            )
            
            let response: LearningSearchResponse = try await performRequest(
                endpoint: "/search",
                method: LearningHTTPMethod.POST,
                body: searchRequest
            )
            
            print("✅ NETWORK FETCH: Successfully fetched \(response.resources.count) resources for '\(topic)'")
            lastError = nil
            isConnected = true
            
            return response.resources
            
        } catch let error as LearningAPIError {
            print("❌ API ERROR: \(error.localizedDescription)")
            lastError = error
            throw error
        } catch {
            print("❌ NETWORK ERROR: \(error.localizedDescription)")
            let apiError = LearningAPIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    /// Search resources with advanced filters
    func searchResources(_ searchRequest: LearningSearchRequest) async throws -> LearningSearchResponse {
        let requestId = UUID()
        print("🔍 SEARCH: Starting search request \(requestId) with query: '\(searchRequest.query)'")
        
        activeRequests.insert(requestId)
        isLoading = true
        
        defer {
            activeRequests.remove(requestId)
            if activeRequests.isEmpty {
                isLoading = false
            }
        }
        
        do {
            let response: LearningSearchResponse = try await performRequest(
                endpoint: "/search/advanced",
                method: LearningHTTPMethod.POST,
                body: searchRequest
            )
            
            print("✅ SEARCH: Found \(response.resources.count) results for '\(searchRequest.query)'")
            lastError = nil
            
            return response
            
        } catch let error as LearningAPIError {
            print("❌ SEARCH ERROR: \(error.localizedDescription)")
            lastError = error
            throw error
        } catch {
            print("❌ SEARCH NETWORK ERROR: \(error.localizedDescription)")
            let apiError = LearningAPIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    /// Get learning recommendations
    func getRecommendations(for userId: String, limit: Int = 10) async throws -> [LearningResource] {
        let response: LearningRecommendationsResponse = try await performRequest(
            endpoint: "/recommendations/\(userId)",
            method: LearningHTTPMethod.GET,
            body: nil as EmptyRequestBody?
        )
        
        return response.recommendations
    }
    
    /// Get learning categories
    func getCategories() async throws -> [LearningCategory] {
        let response: LearningCategoriesResponse = try await performRequest(
            endpoint: "/categories",
            method: LearningHTTPMethod.GET,
            body: nil as EmptyRequestBody?
        )
        
        return response.categories
    }
    
    /// Get trending topics
    func getTrendingTopics(limit: Int = 20) async throws -> [String] {
        let response: TrendingTopicsResponse = try await performRequest(
            endpoint: "/trending?limit=\(limit)",
            method: LearningHTTPMethod.GET,
            body: nil as EmptyRequestBody?
        )
        
        return response.topics
    }
    
    /// Update learning progress
    func updateProgress(resourceId: String, progress: LearningProgress) async throws {
        let _: EmptyAPIResponse = try await performRequest(
            endpoint: "/progress/\(resourceId)",
            method: LearningHTTPMethod.PATCH,
            body: progress
        )
        
        print("✅ PROGRESS: Updated progress for resource \(resourceId)")
    }
    
    /// Health check endpoint
    func healthCheck() async throws -> LearningHealthResponse {
        return try await performRequest(
            endpoint: "/health",
            method: LearningHTTPMethod.GET,
            body: nil as EmptyRequestBody?
        )
    }
}

// MARK: - Private Request Handler
private extension LearningAPIService {
    
    /// Generic request performer with robust error handling
    func performRequest<T: Codable, B: Codable>(
        endpoint: String,
        method: LearningHTTPMethod,
        body: B?
    ) async throws -> T {
        
        // Construct URL
        guard let url = URL(string: baseURL + endpoint) else {
            throw LearningAPIError.invalidURL(baseURL + endpoint)
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("LyoApp/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add auth token if available
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add request body if provided
        if let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
            } catch {
                throw LearningAPIError.encodingError(error)
            }
        }
        
        // Perform request
        do {
            let (data, response) = try await session.data(for: request)
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LearningAPIError.invalidResponse
            }
            
            // Handle status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode response
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw LearningAPIError.decodingError(error)
                }
                
            case 400:
                throw LearningAPIError.badRequest("Invalid request parameters")
            case 401:
                throw LearningAPIError.unauthorized
            case 403:
                throw LearningAPIError.forbidden
            case 404:
                throw LearningAPIError.notFound
            case 429:
                throw LearningAPIError.rateLimited
            case 500...599:
                throw LearningAPIError.serverError("Server error (\(httpResponse.statusCode))")
            default:
                throw LearningAPIError.unknownError("Unexpected status code: \(httpResponse.statusCode)")
            }
            
        } catch {
            // Handle network errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw LearningAPIError.timeout
                case .notConnectedToInternet, .networkConnectionLost:
                    isConnected = false
                    throw LearningAPIError.networkError(urlError)
                default:
                    throw LearningAPIError.networkError(urlError)
                }
            } else if let apiError = error as? LearningAPIError {
                throw apiError
            } else {
                throw LearningAPIError.networkError(error)
            }
        }
    }
    
    /// Get authentication token from storage
    func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "learning_auth_token")
    }
    
    /// Check network connectivity
    func checkConnectivity() async -> Bool {
        do {
            let _ = try await healthCheck()
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Error Types
enum LearningAPIError: Error, LocalizedError {
    case invalidURL(String)
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case encodingError(Error)
    case badRequest(String)
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case timeout
    case serverError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Rate limit exceeded"
        case .timeout:
            return "Request timed out"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Request Models
struct LearningSearchRequest: Codable {
    let query: String
    let limit: Int
    let offset: Int
    let filters: SearchFilters?
    
    init(query: String, limit: Int = 20, offset: Int = 0, filters: SearchFilters? = nil) {
        self.query = query
        self.limit = limit
        self.offset = offset
        self.filters = filters
    }
}

struct SearchFilters: Codable {
    let categories: [String]?
    let difficulty: String?
    let duration: String?
    let type: String?
}

struct LearningProgress: Codable {
    let percentage: Double
    let timeSpent: Int
    let lastAccessed: Date
    let completed: Bool
}

struct EmptyRequestBody: Codable {}

// MARK: - Response Models
struct LearningSearchResponse: Codable {
    let resources: [LearningResource]
    let total: Int
    let page: Int
    let hasMore: Bool
}

struct LearningResource: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let difficulty: String
    let duration: Int
    let type: String
    let url: String
    let thumbnailUrl: String?
    let rating: Double
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
}

struct LearningRecommendationsResponse: Codable {
    let recommendations: [LearningResource]
    let reason: String
}

struct LearningCategoriesResponse: Codable {
    let categories: [LearningCategory]
}

struct LearningCategory: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let resourceCount: Int
}

struct TrendingTopicsResponse: Codable {
    let topics: [String]
    let period: String
}

struct LearningHealthResponse: Codable {
    let status: String
    let timestamp: Date
    let version: String
    let uptime: Int
}

struct EmptyAPIResponse: Codable {}
