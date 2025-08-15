import Foundation
import SwiftUI

/**
 * YouTube Education API Service
 * Integrates with YouTube Data API v3 to fetch educational content
 */
class YouTubeEducationService: ObservableObject {
    private let baseURL = "https://www.googleapis.com/youtube/v3"
    private let apiKey = APIKeys.youtubeAPIKey // You'll need to add this to APIKeys
    
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Search Educational Videos
    func searchEducationalVideos(
        query: String,
        maxResults: Int = 20,
        category: String = "Education"
    ) async throws -> [EducationalVideo] {
        
        guard !apiKey.isEmpty && apiKey != "YOUR_YOUTUBE_API_KEY" else {
            throw APIError.apiKeyMissing
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search?part=snippet&q=\(encodedQuery)&type=video&videoCategoryId=27&maxResults=\(maxResults)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
                guard let httpResponse = response as? HTTPURLResponse,
                            httpResponse.statusCode == 200 else {
                        throw APIError.networkError(NSError(domain: "YouTube", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch YouTube data"]))
                }
        
        let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        
        // Convert to EducationalVideo objects
        var videos: [EducationalVideo] = []
        
        for item in searchResponse.items {
            // Get additional video details
            if let videoDetails = try? await getVideoDetails(videoId: item.id.videoId) {
                videos.append(videoDetails)
            }
        }
        
        return videos
    }
    
    // MARK: - Get Video Details
    func getVideoDetails(videoId: String) async throws -> EducationalVideo {
        let urlString = "\(baseURL)/videos?part=snippet,contentDetails,statistics&id=\(videoId)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(YouTubeVideoResponse.self, from: data)
        
        guard let item = response.items.first else {
            throw APIError.noData
        }
        
        return EducationalVideo(
            id: UUID(),
            title: item.snippet.title,
            description: item.snippet.description,
            thumbnailURL: item.snippet.thumbnails.high?.url ?? item.snippet.thumbnails.default.url,
            videoURL: "https://www.youtube.com/watch?v=\(videoId)",
            duration: parseDuration(item.contentDetails.duration),
            instructor: item.snippet.channelTitle,
            category: "YouTube Education",
            difficulty: .beginner, // Could be determined by AI analysis
            tags: item.snippet.tags ?? [],
            rating: 4.5, // Could calculate from likes/dislikes if available
            viewCount: Int(item.statistics.viewCount) ?? 0,
            isBookmarked: false,
            watchProgress: 0.0,
            publishedDate: parseDate(item.snippet.publishedAt),
            language: item.snippet.defaultLanguage ?? "en"
        )
    }
    
    // MARK: - Search Educational Channels
    func searchEducationalChannels(query: String) async throws -> [YouTubeChannel] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search?part=snippet&q=\(encodedQuery)&type=channel&maxResults=10&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        
        return response.items.compactMap { item in
            guard item.id.kind == "youtube#channel" else { return nil }
            
            return YouTubeChannel(
                id: item.id.channelId ?? "",
                name: item.snippet.title,
                description: item.snippet.description,
                thumbnailURL: item.snippet.thumbnails.high?.url ?? "",
                subscriberCount: 0, // Would need separate API call
                videoCount: 0
            )
        }
    }
    
    // MARK: - Get Popular Educational Videos
    func getPopularEducationalVideos(category: String = "Education") async throws -> [EducationalVideo] {
        let urlString = "\(baseURL)/videos?part=snippet,contentDetails,statistics&chart=mostPopular&videoCategoryId=27&maxResults=20&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(YouTubeVideoResponse.self, from: data)
        
        return response.items.compactMap { item in
            EducationalVideo(
                id: UUID(),
                title: item.snippet.title,
                description: item.snippet.description,
                thumbnailURL: item.snippet.thumbnails.high?.url ?? item.snippet.thumbnails.default.url,
                videoURL: "https://www.youtube.com/watch?v=\(item.id)",
                duration: parseDuration(item.contentDetails.duration),
                instructor: item.snippet.channelTitle,
                category: "YouTube Education",
                difficulty: .beginner,
                tags: item.snippet.tags ?? [],
                rating: 4.5,
                viewCount: Int(item.statistics.viewCount) ?? 0,
                isBookmarked: false,
                watchProgress: 0.0,
                publishedDate: parseDate(item.snippet.publishedAt),
                language: item.snippet.defaultLanguage ?? "en"
            )
        }
    }
    
    // MARK: - Helper Functions
    private func parseDuration(_ duration: String) -> TimeInterval {
        // Parse ISO 8601 duration format (PT4M13S)
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.firstMatch(in: duration, range: NSRange(duration.startIndex..., in: duration))
        
        var totalSeconds: TimeInterval = 0
        
        if let hoursRange = matches?.range(at: 1), hoursRange.location != NSNotFound {
            let hours = Int(String(duration[Range(hoursRange, in: duration)!])) ?? 0
            totalSeconds += TimeInterval(hours * 3600)
        }
        
        if let minutesRange = matches?.range(at: 2), minutesRange.location != NSNotFound {
            let minutes = Int(String(duration[Range(minutesRange, in: duration)!])) ?? 0
            totalSeconds += TimeInterval(minutes * 60)
        }
        
        if let secondsRange = matches?.range(at: 3), secondsRange.location != NSNotFound {
            let seconds = Int(String(duration[Range(secondsRange, in: duration)!])) ?? 0
            totalSeconds += TimeInterval(seconds)
        }
        
        return totalSeconds
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - YouTube API Response Models
struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Codable {
    let id: YouTubeItemId
    let snippet: YouTubeSnippet
}

struct YouTubeItemId: Codable {
    let kind: String
    let videoId: String?
    let channelId: String?
}

struct YouTubeVideoResponse: Codable {
    let items: [YouTubeVideoItem]
}

struct YouTubeVideoItem: Codable {
    let id: String
    let snippet: YouTubeSnippet
    let contentDetails: YouTubeContentDetails
    let statistics: YouTubeStatistics
}

struct YouTubeSnippet: Codable {
    let title: String
    let description: String
    let channelTitle: String
    let publishedAt: String
    let thumbnails: YouTubeThumbnails
    let tags: [String]?
    let defaultLanguage: String?
}

struct YouTubeThumbnails: Codable {
    let `default`: YouTubeThumbnail
    let medium: YouTubeThumbnail?
    let high: YouTubeThumbnail?
    let standard: YouTubeThumbnail?
    let maxres: YouTubeThumbnail?
}

struct YouTubeThumbnail: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

struct YouTubeContentDetails: Codable {
    let duration: String
    let dimension: String?
    let definition: String?
}

struct YouTubeStatistics: Codable {
    let viewCount: String
    let likeCount: String?
    let dislikeCount: String?
    let commentCount: String?
}

struct YouTubeChannel {
    let id: String
    let name: String
    let description: String
    let thumbnailURL: String
    let subscriberCount: Int
    let videoCount: Int
}

// Note: Using canonical APIError defined in APIKeys.swift
