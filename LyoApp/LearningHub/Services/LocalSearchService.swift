import Foundation

// MARK: - Local Search Service
/// Service for searching the local database (CoreData/SwiftData)
/// This handles offline search capabilities and cached data
struct LocalSearchService {
    
    // MARK: - Search Methods
    
    /// Search for learning resources in the local cache
    static func search(_ term: String) async -> [LearningResource] {
        // For now, return filtered sample data to test the UI
        print("🔍 DEBUG: Searching local database for '\(term)'...")
        
        // Simulate database search delay
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Filter sample resources by search term
        let filteredResources = LearningResource.sampleResources.filter { resource in
            resource.title.localizedCaseInsensitiveContains(term) ||
            resource.description.localizedCaseInsensitiveContains(term) ||
            resource.tags.contains { $0.localizedCaseInsensitiveContains(term) }
        }
        
        print("📦 Found \(filteredResources.count) local results for '\(term)'")
        return filteredResources
    }
    
    /// Get recent search results from cache
    static func getRecentSearches() async -> [String] {
        // TODO: Implement with actual local storage
        return [
            "SwiftUI Animation",
            "Combine Framework", 
            "MVVM Architecture",
            "Async/Await in Swift",
            "iOS Design Patterns"
        ]
    }
    
    /// Save a resource to local cache
    static func cacheResource(_ resource: LearningResource) async {
        print("💾 Caching resource: \(resource.title)")
        // TODO: Implement with CoreData/SwiftData
    }
    
    /// Get cached resources by category
    static func getCachedResources(for contentType: LearningResource.ContentType) async -> [LearningResource] {
        let filtered = LearningResource.sampleResources.filter { $0.contentType == contentType }
        print("📚 Found \(filtered.count) cached \(contentType.displayName) resources")
        return filtered
    }
    
    /// Clear old cache entries
    static func clearOldCache() async {
        print("🧹 Clearing old cache entries...")
        // TODO: Implement cache cleanup logic
    }
}

// MARK: - Search Configuration
extension LocalSearchService {
    struct SearchConfig {
        static let maxResults = 50
        static let minSearchLength = 2
        static let cacheTimeout: TimeInterval = 3600 // 1 hour
    }
}
