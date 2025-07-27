import Foundation
import SwiftUI

/**
 * Comprehensive Educational Content Manager
 * Integrates multiple educational content APIs and provides unified search
 */
@MainActor
class EducationalContentManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var searchResults: [EducationalContentItem] = []
    @Published var featuredContent: [EducationalContentItem] = []
    @Published var recentlyViewed: [EducationalContentItem] = []
    @Published var bookmarkedContent: [EducationalContentItem] = []
    @Published var error: String?
    
    // MARK: - Services
    private let youtubeService = YouTubeEducationService()
    private let booksService = GoogleBooksService()
    private let podcastService = PodcastEducationService()
    private let coursesService = FreeCoursesService()
    
    // MARK: - Cache
    private var contentCache: [String: [EducationalContentItem]] = [:]
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    private var cacheTimestamps: [String: Date] = [:]
    
    // MARK: - Search All Content Types
    func searchAllContent(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isLoading = true
        error = nil
        searchResults = []
        
        do {
            // Check cache first
            if let cachedResults = getCachedResults(for: query) {
                searchResults = cachedResults
                isLoading = false
                return
            }
            
            // Perform parallel searches across all content types
            async let youtubeVideos = searchYouTubeContent(query: query)
            async let googleBooks = searchBooksContent(query: query)
            async let podcasts = searchPodcastContent(query: query)
            async let freeCourses = searchFreeCourses(query: query)
            
            // Collect all results
            let (videos, books, podcastEpisodes, courses) = try await (youtubeVideos, googleBooks, podcasts, freeCourses)
            
            // Combine and sort results
            var allContent: [EducationalContentItem] = []
            allContent.append(contentsOf: videos.map { .video($0) })
            allContent.append(contentsOf: books.map { .ebook($0) })
            allContent.append(contentsOf: podcastEpisodes.map { .podcast($0) })
            allContent.append(contentsOf: courses.map { .course($0) })
            
            // Sort by relevance (you can implement your own scoring algorithm)
            allContent = sortByRelevance(allContent, query: query)
            
            // Cache the results
            cacheResults(allContent, for: query)
            
            searchResults = allContent
            
        } catch {
            self.error = "Search failed: \(error.localizedDescription)"
            print("Search error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Search by Category
    func searchByCategory(_ category: String) async {
        isLoading = true
        error = nil
        
        do {
            async let videos = youtubeService.searchEducationalVideos(query: category, maxResults: 10)
            async let books = booksService.searchByCategory(category: category, maxResults: 10)
            async let podcasts = podcastService.searchByCategory(category: category, maxResults: 10)
            
            let (videoResults, bookResults, podcastResults) = try await (videos, books, podcasts)
            
            var categoryContent: [EducationalContentItem] = []
            categoryContent.append(contentsOf: videoResults.map { .video($0) })
            categoryContent.append(contentsOf: bookResults.map { .ebook($0) })
            categoryContent.append(contentsOf: podcastResults.map { .podcast($0) })
            
            searchResults = categoryContent.shuffled()
            
        } catch {
            self.error = "Category search failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Load Featured Content
    func loadFeaturedContent() async {
        do {
            async let popularVideos = youtubeService.getPopularEducationalVideos()
            async let popularBooks = booksService.getPopularEducationalBooks()
            async let trendingPodcasts = podcastService.getTrendingEducationalPodcasts()
            
            let (videos, books, podcasts) = try await (popularVideos, popularBooks, trendingPodcasts)
            
            var featured: [EducationalContentItem] = []
            featured.append(contentsOf: Array(videos.prefix(5)).map { .video($0) })
            featured.append(contentsOf: Array(books.prefix(5)).map { .ebook($0) })
            featured.append(contentsOf: Array(podcasts.prefix(5)).map { .podcast($0) })
            
            featuredContent = featured.shuffled()
            
        } catch {
            print("Failed to load featured content: \(error)")
        }
    }
    
    // MARK: - Bookmark Content
    func toggleBookmark(for item: EducationalContentItem) {
        if bookmarkedContent.contains(where: { $0.id == item.id }) {
            bookmarkedContent.removeAll { $0.id == item.id }
        } else {
            bookmarkedContent.append(item)
        }
        
        // Save to UserDefaults or your preferred persistence layer
        saveBookmarkedContent()
    }
    
    func isBookmarked(_ item: EducationalContentItem) -> Bool {
        return bookmarkedContent.contains { $0.id == item.id }
    }
    
    // MARK: - Recently Viewed
    func addToRecentlyViewed(_ item: EducationalContentItem) {
        // Remove if already exists
        recentlyViewed.removeAll { $0.id == item.id }
        
        // Add to beginning
        recentlyViewed.insert(item, at: 0)
        
        // Keep only last 20 items
        if recentlyViewed.count > 20 {
            recentlyViewed = Array(recentlyViewed.prefix(20))
        }
        
        saveRecentlyViewed()
    }
    
    // MARK: - Private Search Methods
    private func searchYouTubeContent(query: String) async throws -> [EducationalVideo] {
        return try await youtubeService.searchEducationalVideos(query: query, maxResults: 15)
    }
    
    private func searchBooksContent(query: String) async throws -> [Ebook] {
        return try await booksService.searchBooks(query: query, maxResults: 15, filter: .freeEbooks)
    }
    
    private func searchPodcastContent(query: String) async throws -> [PodcastEpisode] {
        return try await podcastService.searchEducationalPodcasts(query: query, maxResults: 10)
    }
    
    private func searchFreeCourses(query: String) async throws -> [Course] {
        return try await coursesService.searchCourses(query: query, maxResults: 10)
    }
    
    // MARK: - Relevance Sorting
    private func sortByRelevance(_ content: [EducationalContentItem], query: String) -> [EducationalContentItem] {
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        return content.sorted { item1, item2 in
            let score1 = calculateRelevanceScore(for: item1, queryWords: queryWords)
            let score2 = calculateRelevanceScore(for: item2, queryWords: queryWords)
            return score1 > score2
        }
    }
    
    private func calculateRelevanceScore(for item: EducationalContentItem, queryWords: [String]) -> Double {
        let title = item.title.lowercased()
        let description = item.description.lowercased()
        
        var score: Double = 0
        
        for word in queryWords {
            // Title matches are worth more
            if title.contains(word) {
                score += 3.0
            }
            
            // Description matches
            if description.contains(word) {
                score += 1.0
            }
            
            // Exact title match gets bonus
            if title == word {
                score += 5.0
            }
        }
        
        // Boost certain content types
        switch item {
        case .course:
            score += 1.0 // Courses are comprehensive
        case .video:
            score += 0.5 // Videos are engaging
        case .ebook:
            score += 0.7 // Books are detailed
        case .podcast:
            score += 0.3 // Podcasts are supplementary
        }
        
        return score
    }
    
    // MARK: - Cache Management
    private func getCachedResults(for query: String) -> [EducationalContentItem]? {
        guard let timestamp = cacheTimestamps[query],
              Date().timeIntervalSince(timestamp) < cacheExpirationTime,
              let cachedContent = contentCache[query] else {
            return nil
        }
        
        return cachedContent
    }
    
    private func cacheResults(_ content: [EducationalContentItem], for query: String) {
        contentCache[query] = content
        cacheTimestamps[query] = Date()
    }
    
    // MARK: - Persistence
    private func saveBookmarkedContent() {
        // Implement persistence to UserDefaults or Core Data
        // For now, using UserDefaults as simple example
        if let data = try? JSONEncoder().encode(bookmarkedContent.map { $0.id }) {
            UserDefaults.standard.set(data, forKey: "bookmarked_content_ids")
        }
    }
    
    private func loadBookmarkedContent() {
        // Load from persistence layer
        // This is a simplified implementation
        if let data = UserDefaults.standard.data(forKey: "bookmarked_content_ids"),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            // You would need to reconstruct the full objects from IDs
            print("Loaded \(ids.count) bookmarked items")
        }
    }
    
    private func saveRecentlyViewed() {
        if let data = try? JSONEncoder().encode(recentlyViewed.map { $0.id }) {
            UserDefaults.standard.set(data, forKey: "recently_viewed_ids")
        }
    }
    
    // MARK: - Initialization
    init() {
        loadBookmarkedContent()
        Task {
            await loadFeaturedContent()
        }
    }
}

// MARK: - Extended EducationalContentItem
extension EducationalContentItem {
    var description: String {
        switch self {
        case .course(let course):
            return course.description
        case .video(let video):
            return video.description
        case .ebook(let ebook):
            return ebook.description
        case .podcast(let podcast):
            return podcast.description
        }
    }
    
    var instructor: String {
        switch self {
        case .course(let course):
            return course.instructor
        case .video(let video):
            return video.instructor
        case .ebook(let ebook):
            return ebook.author
        case .podcast(let podcast):
            return podcast.showName
        }
    }
    
    var rating: Double {
        switch self {
        case .course(let course):
            return course.rating
        case .video(let video):
            return video.rating
        case .ebook(let ebook):
            return ebook.rating
        case .podcast(let podcast):
            return podcast.rating
        }
    }
    
    var contentType: EducationalContentType {
        switch self {
        case .course:
            return .course
        case .video:
            return .video
        case .ebook:
            return .ebook
        case .podcast:
            return .podcast
        }
    }
}

// MARK: - Search Suggestions
extension EducationalContentManager {
    func getSearchSuggestions(for query: String) -> [String] {
        let suggestions = [
            // Programming
            "Swift programming", "Python basics", "JavaScript fundamentals", "Web development",
            "iOS development", "Android development", "Data structures", "Algorithms",
            
            // Science
            "Physics", "Chemistry", "Biology", "Mathematics", "Statistics", "Calculus",
            "Linear algebra", "Quantum physics", "Organic chemistry", "Genetics",
            
            // Business
            "Marketing", "Finance", "Accounting", "Entrepreneurship", "Management",
            "Business strategy", "Economics", "Investment", "Leadership",
            
            // Design
            "UI/UX design", "Graphic design", "Web design", "Adobe Photoshop",
            "Figma", "Design thinking", "Typography", "Color theory",
            
            // Languages
            "Spanish", "French", "German", "Japanese", "Chinese", "English grammar",
            "Language learning", "Vocabulary", "Pronunciation",
            
            // General
            "History", "Philosophy", "Psychology", "Art", "Music theory",
            "Creative writing", "Public speaking", "Critical thinking"
        ]
        
        return suggestions.filter { $0.lowercased().contains(query.lowercased()) }
    }
}
