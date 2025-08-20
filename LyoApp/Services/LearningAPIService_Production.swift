import Foundation
import SwiftUI
import Combine

// MARK: - Production Learning API Service
@MainActor
class LearningAPIService: ObservableObject {
    static let shared = LearningAPIService()
    
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        #if DEBUG
        self.baseURL = "http://localhost:8000/api/v1"
        #else
        self.baseURL = "https://api.lyo.app/api/v1"
        #endif
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        print("✅ Production LearningAPIService initialized with baseURL: \(baseURL)")
    }
    
    // MARK: - Core API Methods
    
    func fetchResources(
        query: String? = nil,
        contentType: String? = nil,
        difficulty: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [LearningResource] {
        
        isLoading = true
        defer { isLoading = false }
        
        var components = URLComponents(string: "\(baseURL)/learning-resources")!
        var queryItems: [URLQueryItem] = []
        
        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        if let contentType = contentType {
            queryItems.append(URLQueryItem(name: "type", value: contentType))
        }
        if let difficulty = difficulty {
            queryItems.append(URLQueryItem(name: "difficulty", value: difficulty))
        }
        queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        queryItems.append(URLQueryItem(name: "offset", value: "\(offset)"))
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        do {
            let (data, response) = try await session.data(from: components.url!)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            let result = try decoder.decode(LearningResourceResponse.self, from: data)
            
            print("✅ Fetched \(result.resources.count) resources from API")
            return result.resources
            
        } catch {
            print("❌ API Error: \(error)")
            
            // Fallback to cached/local data if available
            return try await fetchLocalResources(query: query, contentType: contentType)
        }
    }
    
    func fetchTrendingResources(limit: Int = 10) async throws -> [LearningResource] {
        return try await fetchResources(query: "trending", limit: limit)
    }
    
    func fetchFeaturedResources(limit: Int = 5) async throws -> [LearningResource] {
        return try await fetchResources(query: "featured", limit: limit)
    }
    
    func searchResources(query: String, filters: SearchFilters? = nil) async throws -> [LearningResource] {
        return try await fetchResources(
            query: query,
            contentType: filters?.contentType,
            difficulty: filters?.difficulty,
            limit: filters?.limit ?? 20,
            offset: filters?.offset ?? 0
        )
    }
    
    // MARK: - Fallback Methods
    
    private func fetchLocalResources(query: String?, contentType: String?) async throws -> [LearningResource] {
        // Return sample data as fallback
        print("📱 Using local fallback data")
        return LearningResource.sampleResources.filter { resource in
            var matches = true
            
            if let query = query, !query.isEmpty {
                matches = matches && (
                    resource.title.localizedCaseInsensitiveContains(query) ||
                    resource.description.localizedCaseInsensitiveContains(query)
                )
            }
            
            if let contentType = contentType {
                matches = matches && resource.contentType.rawValue == contentType
            }
            
            return matches
        }
    }
}

// MARK: - Supporting Models

struct LearningResourceResponse: Codable {
    let resources: [LearningResource]
    let totalCount: Int?
    let hasMore: Bool?
    let nextOffset: Int?
}

struct SearchFilters {
    var contentType: String?
    var difficulty: String?
    var duration: String?
    var rating: Double?
    var limit: Int = 20
    var offset: Int = 0
}
