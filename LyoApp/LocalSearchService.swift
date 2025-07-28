import Foundation

// MARK: - Local Search Service
/// Placeholder for searching the local CoreData/SwiftData cache
struct LocalSearchService {
    static func search(_ term: String) async -> [LearningResource] {
        print("DEBUG: Searching local database for '\(term)'...")
        
        // Return mock data to test your UI
        // In a real implementation, this would query CoreData or SwiftData
        return LearningResource.sampleResources.filter { resource in
            resource.title.localizedCaseInsensitiveContains(term) ||
            resource.description.localizedCaseInsensitiveContains(term) ||
            resource.tags.contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }
    
    static func getRecentSearches() -> [String] {
        // Return mock recent searches
        return ["SwiftUI", "iOS Development", "Machine Learning", "Python"]
    }
    
    static func saveRecentSearch(_ term: String) {
        print("DEBUG: Saving recent search: '\(term)'")
        // In a real implementation, this would save to UserDefaults or local storage
    }
}
