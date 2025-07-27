import SwiftUI
import Combine

// MARK: - Search View Model
/// Manages search state and debounced search functionality using Combine
@MainActor
class SearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var searchHistory: [String] = []
    @Published var recentSearches: [String] = []
    @Published var searchSuggestions: [String] = []
    
    // MARK: - Private Properties
    private var searchCancellables = Set<AnyCancellable>()
    private let searchHistoryKey = "LearningSearchHistory"
    private let maxSearchHistory = 10
    private let maxRecentSearches = 5
    
    // Search debounce configuration
    private let searchDebounceInterval: TimeInterval = 0.5
    private let suggestionDebounceInterval: TimeInterval = 0.3
    
    // Sample search suggestions for different contexts
    private let defaultSuggestions = [
        "SwiftUI tutorial",
        "iOS development",
        "Machine learning basics",
        "Python programming",
        "Web development",
        "Data science",
        "JavaScript fundamentals",
        "React Native",
        "Flutter development",
        "Backend development"
    ]
    
    private let trendingSuggestions = [
        "AI and ChatGPT",
        "Blockchain development",
        "Cloud computing AWS",
        "Cybersecurity basics",
        "DevOps practices",
        "Mobile app design",
        "Database management",
        "API development"
    ]
    
    // MARK: - Initialization
    init() {
        setupSearchPipeline()
        loadSearchHistory()
        generateInitialSuggestions()
        
        print("🔍 SEARCH MODEL: Initialized with \(searchHistory.count) history items")
    }
    
    // MARK: - Public Methods
    
    /// Updates search text and triggers debounced search
    func updateSearchText(_ text: String) {
        searchText = text
        
        if !text.isEmpty && !searchHistory.contains(text) {
            addToSearchHistory(text)
        }
        
        print("🔍 SEARCH MODEL: Updated search text to '\(text)'")
    }
    
    /// Clears current search and resets to initial state
    func clearSearch() {
        searchText = ""
        isSearching = false
        generateInitialSuggestions()
        
        print("🧹 SEARCH MODEL: Search cleared")
    }
    
    /// Adds a search term to history
    func addToSearchHistory(_ term: String) {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTerm.isEmpty,
              !searchHistory.contains(trimmedTerm) else {
            return
        }
        
        // Add to beginning of array
        searchHistory.insert(trimmedTerm, at: 0)
        
        // Limit history size
        if searchHistory.count > maxSearchHistory {
            searchHistory = Array(searchHistory.prefix(maxSearchHistory))
        }
        
        // Update recent searches (subset of history)
        updateRecentSearches()
        
        // Persist to UserDefaults
        saveSearchHistory()
        
        print("📝 SEARCH MODEL: Added '\(trimmedTerm)' to search history")
    }
    
    /// Removes a specific term from search history
    func removeFromHistory(_ term: String) {
        searchHistory.removeAll { $0 == term }
        updateRecentSearches()
        saveSearchHistory()
        
        print("🗑️ SEARCH MODEL: Removed '\(term)' from history")
    }
    
    /// Clears all search history
    func clearSearchHistory() {
        searchHistory.removeAll()
        recentSearches.removeAll()
        saveSearchHistory()
        
        print("🧹 SEARCH MODEL: Cleared all search history")
    }
    
    /// Performs immediate search without debouncing
    func performImmediateSearch(_ query: String) {
        searchText = query
        isSearching = true
        addToSearchHistory(query)
        
        print("⚡ SEARCH MODEL: Performing immediate search for '\(query)'")
    }
    
    /// Generates contextual search suggestions
    func generateSuggestions(for context: SearchContext = .general) {
        let baseSuggestions: [String]
        
        switch context {
        case .general:
            baseSuggestions = defaultSuggestions
        case .trending:
            baseSuggestions = trendingSuggestions
        case .personalized:
            baseSuggestions = generatePersonalizedSuggestions()
        }
        
        // Mix with recent searches for personalization
        let mixedSuggestions = (recentSearches + baseSuggestions)
            .prefix(8)
            .shuffled()
        
        searchSuggestions = Array(mixedSuggestions)
        
        print("💡 SEARCH MODEL: Generated \(searchSuggestions.count) suggestions for \(context)")
    }
}

// MARK: - Private Methods
private extension SearchViewModel {
    
    /// Sets up the search pipeline with Combine
    func setupSearchPipeline() {
        // Main search debouncing
        $searchText
            .debounce(for: .milliseconds(Int(searchDebounceInterval * 1000)), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.handleDebouncedSearch(searchText)
            }
            .store(in: &searchCancellables)
        
        // Suggestion generation pipeline
        $searchText
            .debounce(for: .milliseconds(Int(suggestionDebounceInterval * 1000)), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.updateSuggestionsForQuery(searchText)
            }
            .store(in: &searchCancellables)
        
        print("🔄 SEARCH MODEL: Search pipeline configured with debouncing")
    }
    
    /// Handles debounced search execution
    func handleDebouncedSearch(_ query: String) {
        guard !query.isEmpty else {
            isSearching = false
            return
        }
        
        isSearching = true
        
        // This would trigger the actual search in the parent view
        // The parent view listens to the debounced searchText publisher
        
        print("⏱️ SEARCH MODEL: Debounced search triggered for '\(query)'")
    }
    
    /// Updates search suggestions based on current query
    func updateSuggestionsForQuery(_ query: String) {
        guard !query.isEmpty else {
            generateInitialSuggestions()
            return
        }
        
        let filteredSuggestions = (defaultSuggestions + trendingSuggestions + searchHistory)
            .filter { suggestion in
                suggestion.lowercased().contains(query.lowercased()) && suggestion != query
            }
            .prefix(6)
        
        searchSuggestions = Array(filteredSuggestions)
        
        print("🎯 SEARCH MODEL: Updated suggestions for query '\(query)' - \(searchSuggestions.count) matches")
    }
    
    /// Generates initial suggestions when no query is present
    func generateInitialSuggestions() {
        // Combine recent searches with trending suggestions
        let combined = (recentSearches + trendingSuggestions.prefix(6))
            .prefix(8)
        
        searchSuggestions = Array(combined)
        
        print("🌟 SEARCH MODEL: Generated \(searchSuggestions.count) initial suggestions")
    }
    
    /// Updates recent searches based on search history
    func updateRecentSearches() {
        recentSearches = Array(searchHistory.prefix(maxRecentSearches))
    }
    
    /// Generates personalized suggestions based on search history
    func generatePersonalizedSuggestions() -> [String] {
        // Extract keywords from search history to generate personalized suggestions
        let keywords = searchHistory.flatMap { searchTerm in
            searchTerm.lowercased().split(separator: " ").map(String.init)
        }
        
        let keywordFrequency = Dictionary(grouping: keywords) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        // Generate suggestions based on frequent keywords
        let personalizedSuggestions = keywordFrequency.prefix(5).compactMap { keyword, _ in
            // Find suggestions that contain this keyword
            defaultSuggestions.first { suggestion in
                suggestion.lowercased().contains(keyword.lowercased())
            }
        }
        
        return personalizedSuggestions + defaultSuggestions.shuffled().prefix(3)
    }
    
    /// Loads search history from UserDefaults
    func loadSearchHistory() {
        if let savedHistory = UserDefaults.standard.array(forKey: searchHistoryKey) as? [String] {
            searchHistory = savedHistory
            updateRecentSearches()
            
            print("📚 SEARCH MODEL: Loaded \(searchHistory.count) items from search history")
        }
    }
    
    /// Saves search history to UserDefaults
    func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: searchHistoryKey)
        
        print("💾 SEARCH MODEL: Saved \(searchHistory.count) items to search history")
    }
}

// MARK: - Supporting Types
extension SearchViewModel {
    
    enum SearchContext {
        case general
        case trending
        case personalized
        
        var displayName: String {
            switch self {
            case .general: return "Popular"
            case .trending: return "Trending"
            case .personalized: return "For You"
            }
        }
    }
}

// MARK: - Search Analytics (for future implementation)
extension SearchViewModel {
    
    /// Tracks search analytics (placeholder for future analytics integration)
    func trackSearchAnalytics(_ query: String, resultCount: Int) {
        let analyticsData: [String: Any] = [
            "search_query": query,
            "result_count": resultCount,
            "search_timestamp": Date().timeIntervalSince1970,
            "user_session": UUID().uuidString
        ]
        
        print("📊 SEARCH ANALYTICS: \(analyticsData)")
        
        // Future: Send to analytics service
        // AnalyticsService.shared.track("search_performed", properties: analyticsData)
    }
    
    /// Tracks search suggestion selection
    func trackSuggestionSelected(_ suggestion: String, position: Int) {
        let analyticsData: [String: Any] = [
            "suggestion_text": suggestion,
            "suggestion_position": position,
            "selection_timestamp": Date().timeIntervalSince1970
        ]
        
        print("📊 SUGGESTION ANALYTICS: \(analyticsData)")
        
        // Future: Send to analytics service
        // AnalyticsService.shared.track("search_suggestion_selected", properties: analyticsData)
    }
}
