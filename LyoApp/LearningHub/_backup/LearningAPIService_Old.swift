import Foundation
import Combine
import SwiftUI

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
                method: .POST,
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
                endpoint: "/search",
                method: .POST,
                body: searchRequest
            )
            
            print("✅ SEARCH: Found \(response.resources.count) results for '\(searchRequest.query)'")
            lastError = nil
            isConnected = true
            
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
    
    /// Get trending/popular resources
    func fetchTrendingResources(limit: Int = 10) async throws -> [LearningResource] {
        print("📈 TRENDING: Fetching trending resources")
        
        do {
            let resources: [LearningResource] = try await performRequest(
                endpoint: "/trending?limit=\(limit)",
                method: .GET
            )
            
            print("✅ TRENDING: Successfully fetched \(resources.count) trending resources")
            return resources
            
        } catch {
            print("❌ TRENDING ERROR: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Get resource recommendations based on user preferences
    func fetchRecommendations(limit: Int = 15) async throws -> [LearningResource] {
        print("🎯 RECOMMENDATIONS: Fetching personalized recommendations")
        
        do {
            let resources: [LearningResource] = try await performRequest(
                endpoint: "/recommendations?limit=\(limit)",
                method: .GET
            )
            
            print("✅ RECOMMENDATIONS: Successfully fetched \(resources.count) recommendations")
            return resources
            
        } catch {
            print("❌ RECOMMENDATIONS ERROR: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Get resource by ID
    func fetchResource(id: UUID) async throws -> LearningResource {
        print("📖 RESOURCE: Fetching resource with ID: \(id)")
        
        do {
            let resource: LearningResource = try await performRequest(
                endpoint: "/resources/\(id.uuidString)",
                method: .GET
            )
            
            print("✅ RESOURCE: Successfully fetched resource: \(resource.title)")
            return resource
            
        } catch {
            print("❌ RESOURCE ERROR: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update resource bookmark status
    func updateBookmark(resourceId: UUID, isBookmarked: Bool) async throws {
        print("🔖 BOOKMARK: Updating bookmark status for \(resourceId) to \(isBookmarked)")
        
        let requestBody = ["isBookmarked": isBookmarked]
        
        do {
            let _: EmptyAPIResponse = try await performRequest(
                endpoint: "/resources/\(resourceId.uuidString)/bookmark",
                method: .PATCH,
                body: requestBody
            )
            
            print("✅ BOOKMARK: Successfully updated bookmark status")
            
        } catch {
            print("❌ BOOKMARK ERROR: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Health Check
    func checkConnection() async throws -> Bool {
        do {
            let _: HealthResponse = try await performRequest(
                endpoint: "/health",
                method: .GET
            )
            
            print("✅ CONNECTION: Backend is healthy")
            isConnected = true
            return true
            
        } catch {
            print("❌ CONNECTION: Backend health check failed - \(error.localizedDescription)")
            isConnected = false
            throw error
        }
    }
}

// MARK: - Private Methods
private extension LearningAPIService {
    
    /// Generic request performer with robust error handling
    func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: (any Codable)? = nil
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
                request.httpBody = try JSONEncoder().encode(body)
                print("📦 REQUEST BODY: \(String(data: request.httpBody!, encoding: .utf8) ?? "Unable to encode")")
            } catch {
                throw LearningAPIError.encodingError(error)
            }
        }
        
        print("🌐 REQUEST: \(method.rawValue) \(url.absoluteString)")
        
        // Perform request
        do {
            let (data, response) = try await session.data(for: request)
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LearningAPIError.invalidResponse("No HTTP response")
            }
            
            print("📥 RESPONSE: HTTP \(httpResponse.statusCode)")
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode response
                break
            case 400:
                throw LearningAPIError.badRequest("Invalid request parameters")
            case 401:
                throw LearningAPIError.unauthorized("Authentication required")
            case 403:
                throw LearningAPIError.forbidden("Access denied")
            case 404:
                throw LearningAPIError.notFound("Resource not found")
            case 429:
                throw LearningAPIError.rateLimited("Too many requests")
            case 500...599:
                throw LearningAPIError.serverError(httpResponse.statusCode, "Server error occurred")
            default:
                throw LearningAPIError.serverError(httpResponse.statusCode, "Unexpected response code")
            }
            
            // Log response data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 RESPONSE DATA: \(responseString.prefix(200))...")
            }
            
            // Decode response
            do {
                let decodedResponse = try decoder.decode(T.self, from: data)
                print("✅ MODEL DECODING: Successfully decoded \(T.self)")
                return decodedResponse
            } catch {
                print("❌ MODEL DECODING ERROR: Failed to decode \(T.self) - \(error)")
                throw LearningAPIError.decodingError(error)
            }
            
        } catch let error as LearningAPIError {
            throw error
        } catch {
            throw LearningAPIError.networkError(error)
        }
    }
    
    /// Get authentication token
    func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "lyo_auth_token")
    }
}

// MARK: - API Error Types
enum LearningAPIError: LocalizedError, Equatable {
    case invalidURL(String)
    case networkError(Error)
    case encodingError(Error)
    case decodingError(Error)
    case invalidResponse(String)
    case badRequest(String)
    case unauthorized(String)
    case forbidden(String)
    case notFound(String)
    case rateLimited(String)
    case serverError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unauthorized(let message):
            return "Unauthorized: \(message)"
        case .forbidden(let message):
            return "Forbidden: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .rateLimited(let message):
            return "Rate limited: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
    
    static func == (lhs: LearningAPIError, rhs: LearningAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL(let lUrl), .invalidURL(let rUrl)):
            return lUrl == rUrl
        case (.badRequest(let lMsg), .badRequest(let rMsg)):
            return lMsg == rMsg
        case (.unauthorized(let lMsg), .unauthorized(let rMsg)):
            return lMsg == rMsg
        case (.forbidden(let lMsg), .forbidden(let rMsg)):
            return lMsg == rMsg
        case (.notFound(let lMsg), .notFound(let rMsg)):
            return lMsg == rMsg
        case (.rateLimited(let lMsg), .rateLimited(let rMsg)):
            return lMsg == rMsg
        case (.serverError(let lCode, let lMsg), .serverError(let rCode, let rMsg)):
            return lCode == rCode && lMsg == rMsg
        default:
            return false
        }
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Response Types
struct EmptyAPIResponse: Codable {}

struct HealthResponse: Codable {
    let status: String
    let timestamp: Date
    let version: String
}
