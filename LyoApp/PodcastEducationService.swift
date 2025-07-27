import Foundation
import SwiftUI

/**
 * Podcast Education Service
 * Integrates with multiple podcast APIs to fetch educational podcast content
 */
class PodcastEducationService: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Search Educational Podcasts
    func searchEducationalPodcasts(query: String, maxResults: Int = 20) async throws -> [PodcastEpisode] {
        // Using multiple free podcast APIs
        async let podcastIndexResults = searchPodcastIndex(query: query, maxResults: maxResults)
        async let iTunesResults = searchiTunesPodcasts(query: query, maxResults: maxResults)
        
        let (podcastIndexEpisodes, iTunesEpisodes) = try await (podcastIndexResults, iTunesResults)
        
        // Combine and deduplicate results
        var allEpisodes = podcastIndexEpisodes
        allEpisodes.append(contentsOf: iTunesEpisodes)
        
        // Remove duplicates based on title similarity
        allEpisodes = removeDuplicates(allEpisodes)
        
        return Array(allEpisodes.prefix(maxResults))
    }
    
    // MARK: - Search by Category
    func searchByCategory(category: String, maxResults: Int = 20) async throws -> [PodcastEpisode] {
        let categoryQueries = [
            "programming": "programming software development coding",
            "science": "science physics chemistry biology",
            "business": "business entrepreneurship finance",
            "design": "design UI UX graphic",
            "languages": "language learning spanish french",
            "history": "history historical",
            "mathematics": "mathematics math calculus",
            "psychology": "psychology mental health"
        ]
        
        let searchQuery = categoryQueries[category.lowercased()] ?? category
        return try await searchEducationalPodcasts(query: searchQuery, maxResults: maxResults)
    }
    
    // MARK: - Get Trending Educational Podcasts
    func getTrendingEducationalPodcasts(maxResults: Int = 20) async throws -> [PodcastEpisode] {
        // Search for popular educational topics
        let trendingTopics = [
            "artificial intelligence",
            "machine learning",
            "climate change",
            "cryptocurrency",
            "space exploration",
            "neuroscience",
            "quantum computing",
            "renewable energy"
        ]
        
        var allEpisodes: [PodcastEpisode] = []
        
        for topic in trendingTopics.prefix(4) { // Limit to prevent too many API calls
            if let episodes = try? await searchEducationalPodcasts(query: topic, maxResults: 5) {
                allEpisodes.append(contentsOf: episodes)
            }
        }
        
        return Array(allEpisodes.shuffled().prefix(maxResults))
    }
    
    // MARK: - Podcast Index API (Free)
    private func searchPodcastIndex(query: String, maxResults: Int) async throws -> [PodcastEpisode] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://api.podcastindex.org/api/1.0/search/byterm?q=\(encodedQuery)&max=\(maxResults)&clean"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        // Add required headers for Podcast Index API
        let apiKey = "YOUR_PODCAST_INDEX_KEY" // You'll need to register at podcastindex.org
        let apiSecret = "YOUR_PODCAST_INDEX_SECRET"
        let epochTime = String(Int(Date().timeIntervalSince1970))
        
        // Create authorization hash (required by Podcast Index)
        let authString = "\(apiKey)\(apiSecret)\(epochTime)"
        let authHash = authString.sha1()
        
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue(epochTime, forHTTPHeaderField: "X-Auth-Date")
        request.setValue(authHash, forHTTPHeaderField: "Authorization")
        request.setValue("LyoApp/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(PodcastIndexResponse.self, from: data)
        
        return response.feeds.compactMap { convertToPodcastEpisode($0) }
    }
    
    // MARK: - iTunes Podcast API (Free)
    private func searchiTunesPodcasts(query: String, maxResults: Int) async throws -> [PodcastEpisode] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://itunes.apple.com/search?term=\(encodedQuery)&media=podcast&entity=podcast&limit=\(maxResults)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(iTunesPodcastResponse.self, from: data)
        
        return response.results.compactMap { convertToPodcastEpisode($0) }
    }
    
    // MARK: - Conversion Functions
    private func convertToPodcastEpisode(_ podcastIndexFeed: PodcastIndexFeed) -> PodcastEpisode? {
        return PodcastEpisode(
            title: podcastIndexFeed.title,
            description: podcastIndexFeed.description ?? "Educational podcast content",
            audioURL: podcastIndexFeed.url ?? "",
            thumbnailURL: podcastIndexFeed.image ?? "",
            duration: TimeInterval(podcastIndexFeed.episodeCount * 1800), // Estimate 30 min per episode
            showName: podcastIndexFeed.title,
            publishedDate: Date(),
            category: podcastIndexFeed.categories?.keys.first ?? "Education",
            difficulty: .beginner,
            tags: [],
            transcript: nil,
            isBookmarked: false,
            playProgress: 0.0
        )
    }
    
    private func convertToPodcastEpisode(_ iTunesResult: iTunesPodcastResult) -> PodcastEpisode? {
        return PodcastEpisode(
            title: iTunesResult.collectionName ?? iTunesResult.trackName ?? "Unknown Podcast",
            description: "Educational podcast from iTunes",
            audioURL: iTunesResult.feedUrl ?? "",
            thumbnailURL: iTunesResult.artworkUrl600 ?? iTunesResult.artworkUrl100 ?? "",
            duration: TimeInterval(iTunesResult.trackTimeMillis ?? 1800000) / 1000, // Convert to seconds
            showName: iTunesResult.artistName ?? "Unknown Artist",
            publishedDate: parseDate(iTunesResult.releaseDate),
            category: iTunesResult.primaryGenreName ?? "Education",
            difficulty: .beginner,
            tags: iTunesResult.genreIds?.map { String($0) } ?? [],
            transcript: nil,
            isBookmarked: false,
            playProgress: 0.0
        )
    }
    
    // MARK: - Helper Functions
    private func removeDuplicates(_ episodes: [PodcastEpisode]) -> [PodcastEpisode] {
        var seen: Set<String> = []
        return episodes.filter { episode in
            let key = episode.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
    }
    
    private func parseDate(_ dateString: String?) -> Date {
        guard let dateString = dateString else { return Date() }
        
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - API Response Models

// Podcast Index API Models
struct PodcastIndexResponse: Codable {
    let status: String
    let feeds: [PodcastIndexFeed]
    let count: Int
    let query: String?
    let description: String
}

struct PodcastIndexFeed: Codable {
    let id: Int
    let title: String
    let url: String?
    let description: String?
    let author: String?
    let ownerName: String?
    let image: String?
    let artwork: String?
    let lastUpdateTime: Int?
    let lastCrawlTime: Int?
    let lastParseTime: Int?
    let lastGoodHttpStatusTime: Int?
    let lastHttpStatus: Int?
    let contentType: String?
    let itunesId: Int?
    let originalUrl: String?
    let link: String?
    let language: String?
    let type: Int?
    let medium: String?
    let dead: Int?
    let episodeCount: Int
    let crawlErrors: Int?
    let parseErrors: Int?
    let categories: [String: String]?
    let locked: Int?
    let imageUrlHash: Int?
}

// iTunes API Models
struct iTunesPodcastResponse: Codable {
    let resultCount: Int
    let results: [iTunesPodcastResult]
}

struct iTunesPodcastResult: Codable {
    let wrapperType: String?
    let kind: String?
    let artistId: Int?
    let collectionId: Int?
    let trackId: Int?
    let artistName: String?
    let collectionName: String?
    let trackName: String?
    let collectionCensoredName: String?
    let trackCensoredName: String?
    let artistViewUrl: String?
    let collectionViewUrl: String?
    let feedUrl: String?
    let trackViewUrl: String?
    let artworkUrl30: String?
    let artworkUrl60: String?
    let artworkUrl100: String?
    let artworkUrl600: String?
    let collectionPrice: Double?
    let trackPrice: Double?
    let releaseDate: String?
    let collectionExplicitness: String?
    let trackExplicitness: String?
    let trackCount: Int?
    let trackTimeMillis: Int?
    let country: String?
    let currency: String?
    let primaryGenreName: String?
    let contentAdvisoryRating: String?
    let genreIds: [Int]?
    let genres: [String]?
}

// MARK: - SHA1 Extension for Podcast Index Auth
extension String {
    func sha1() -> String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// You'll need to add this import at the top of the file
import CommonCrypto
