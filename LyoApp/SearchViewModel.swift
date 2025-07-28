import Foundation
import SwiftUI
import Combine

// MARK: - Search View Model
/// MainActor-marked view model for safe UI updates during search operations
@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [LearningResource] = []
    @Published var isSearching = false
    @Published var recentSearches: [String] = []
    @Published var selectedFilters: [String] = []
    @Published var errorMessage: String?
    
    // Search state
    @Published var hasSearched = false
    @Published var showingSuggestions = false
    
    private var searchTask: Task<Void, Never>?
    
    init() {
        loadRecentSearches()
    }
    
    // MARK: - Search Operations
    func performSearch(_ term: String) async {
        // Cancel any existing search
        searchTask?.cancel()
        
        searchTask = Task {
            // Ensure UI updates happen on main thread
            self.isSearching = true
            self.errorMessage = nil
            self.query = term
            
            do {
                // 1. Query local database first for immediate results
                let localResults = await LocalSearchService.search(term)
                
                // Update UI with local results immediately
                self.results = localResults
                self.hasSearched = true
                
                // 2. Save search term to recent searches
                saveRecentSearch(term)
                
                // 3. Trigger remote semantic fetch in background
                await RemoteAPI.triggerSemanticFetch(query: term)
                
                print("✅ Search completed for: '\(term)', found \(localResults.count) results")
                
            } catch {
                // Handle search errors gracefully
                self.errorMessage = "Search failed. Please try again."
                print("❌ Search error: \(error.localizedDescription)")
            }
            
            self.isSearching = false
        }
        
        await searchTask?.value
    }
    
    func clearSearch() {
        query = ""
        results = []
        hasSearched = false
        errorMessage = nil
        searchTask?.cancel()
    }
    
    // MARK: - Recent Searches
    private func loadRecentSearches() {
        recentSearches = LocalSearchService.getRecentSearches()
    }
    
    private func saveRecentSearch(_ term: String) {
        guard !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add to recent searches, avoiding duplicates
        if let index = recentSearches.firstIndex(of: term) {
            recentSearches.remove(at: index)
        }
        
        recentSearches.insert(term, at: 0)
        
        // Keep only the most recent 10 searches
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        
        LocalSearchService.saveRecentSearch(term)
    }
    
    func removeRecentSearch(_ term: String) {
        recentSearches.removeAll { $0 == term }
    }
    
    // MARK: - Filtering
    func applyFilter(_ filter: String) {
        if selectedFilters.contains(filter) {
            selectedFilters.removeAll { $0 == filter }
        } else {
            selectedFilters.append(filter)
        }
        
        // Re-filter current results
        filterCurrentResults()
    }
    
    private func filterCurrentResults() {
        guard !selectedFilters.isEmpty else { return }
        
        // Apply filters to current results
        // This is a simple implementation - in a real app you might want more sophisticated filtering
        let filteredResults = results.filter { resource in
            selectedFilters.allSatisfy { filter in
                resource.tags.contains(filter) ||
                resource.contentType.rawValue == filter ||
                resource.difficultyLevel?.rawValue == filter
            }
        }
        
        results = filteredResults
    }
    
    // MARK: - Suggestions
    func showSuggestions() {
        showingSuggestions = true
    }
    
    func hideSuggestions() {
        showingSuggestions = false
    }
    
    // MARK: - Cleanup
    deinit {
        searchTask?.cancel()
    }
}

// MARK: - Search Suggestions
extension SearchViewModel {
    var searchSuggestions: [String] {
        if query.isEmpty {
            return [
                "SwiftUI Basics",
                "iOS App Development",
                "Machine Learning",
                "Python Programming",
                "Web Development"
            ]
        } else {
            // Filter suggestions based on current query
            let allSuggestions = [
                "SwiftUI Animation",
                "SwiftUI Navigation",
                "iOS Core Data",
                "iOS Networking",
                "Machine Learning with Python",
                "Python Data Science",
                "Web APIs",
                "JavaScript Fundamentals"
            ]
            
            return allSuggestions.filter { suggestion in
                suggestion.localizedCaseInsensitiveContains(query)
            }
        }
    }
}
