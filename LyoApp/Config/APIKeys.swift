import Foundation

// Centralized API keys for third-party services used by the app.
// Populate via environment variables or XCConfig at build time.
enum APIKeys {
    // YouTube Data API v3 key
    static let youtubeAPIKey: String = ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"] ?? ""

    // Google Books API key
    static let googleBooksAPIKey: String = ProcessInfo.processInfo.environment["GOOGLE_BOOKS_API_KEY"] ?? ""
}
