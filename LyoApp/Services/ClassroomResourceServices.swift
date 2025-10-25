import Foundation

// MARK: - Google Books Service

class GoogleBooksService {
    static let shared = GoogleBooksService()
    private init() {}

    func search(query: String, maxResults: Int = 5) async throws -> [GoogleBook] {
        let apiKey = APIKeys.googleBooksAPIKey
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        let urlString = "https://www.googleapis.com/books/v1/volumes?q=\(encodedQuery)&maxResults=\(maxResults)&key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw ResourceError.invalidURL
        }

        print("📖 [GoogleBooks] Searching for: \(query)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResourceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            print("⚠️ [GoogleBooks] HTTP \(httpResponse.statusCode)")
            throw ResourceError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        print("✅ [GoogleBooks] Found \(result.items?.count ?? 0) books")

        return result.items?.map { item in
            GoogleBook(
                id: item.id,
                title: item.volumeInfo.title,
                authors: item.volumeInfo.authors ?? ["Unknown"],
                description: item.volumeInfo.description ?? "",
                publisher: item.volumeInfo.publisher ?? "Unknown",
                publishedDate: item.volumeInfo.publishedDate ?? "",
                thumbnail: item.volumeInfo.imageLinks?.thumbnail,
                infoLink: item.volumeInfo.infoLink
            )
        } ?? []
    }
}

struct GoogleBooksResponse: Codable {
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Codable {
    let id: String
    let volumeInfo: GoogleVolumeInfo
}

struct GoogleVolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let imageLinks: GoogleImageLinks?
    let infoLink: String
}

struct GoogleImageLinks: Codable {
    let thumbnail: String?
}

struct GoogleBook {
    let id: String
    let title: String
    let authors: [String]
    let description: String
    let publisher: String
    let publishedDate: String
    let thumbnail: String?
    let infoLink: String
}

// MARK: - YouTube Education Service

class YouTubeEducationService {
    static let shared = YouTubeEducationService()
    private init() {}

    func searchEducational(query: String, maxResults: Int = 5) async throws -> [YouTubeVideo] {
        let apiKey = APIKeys.youtubeAPIKey
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        // Add educational keywords to improve results
        let educationalQuery = "\(encodedQuery) tutorial lesson course education"

        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(educationalQuery)&type=video&videoDuration=medium&maxResults=\(maxResults)&key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw ResourceError.invalidURL
        }

        print("🎥 [YouTube] Searching for: \(query)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResourceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            print("⚠️ [YouTube] HTTP \(httpResponse.statusCode)")
            throw ResourceError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)

        print("✅ [YouTube] Found \(result.items.count) videos")

        return result.items.map { item in
            YouTubeVideo(
                videoId: item.id.videoId,
                title: item.snippet.title,
                description: item.snippet.description,
                channelTitle: item.snippet.channelTitle,
                publishedAt: item.snippet.publishedAt,
                thumbnail: item.snippet.thumbnails.medium.url,
                videoUrl: "https://www.youtube.com/watch?v=\(item.id.videoId)"
            )
        }
    }
}

struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Codable {
    let id: YouTubeVideoId
    let snippet: YouTubeSnippet
}

struct YouTubeVideoId: Codable {
    let videoId: String
}

struct YouTubeSnippet: Codable {
    let title: String
    let description: String
    let channelTitle: String
    let publishedAt: String
    let thumbnails: YouTubeThumbnails
}

struct YouTubeThumbnails: Codable {
    let medium: YouTubeThumbnail
}

struct YouTubeThumbnail: Codable {
    let url: String
}

struct YouTubeVideo {
    let videoId: String
    let title: String
    let description: String
    let channelTitle: String
    let publishedAt: String
    let thumbnail: String
    let videoUrl: String
}

// MARK: - Code Execution Service

class CodeExecutionService {
    static let shared = CodeExecutionService()
    private init() {}

    /// Execute Python code using online sandbox
    func executePython(code: String) async throws -> CodeExecutionResult {
        print("💻 [CodeExec] Executing Python code...")

        // Using Judge0 API (free tier)
        let judge0URL = "https://judge0-ce.p.rapidapi.com/submissions"
        let rapidAPIKey = APIKeys.rapidAPIKey // You'll need to add this to APIKeys

        // Create submission
        let submissionBody: [String: Any] = [
            "source_code": code,
            "language_id": 71, // Python 3
            "stdin": ""
        ]

        guard let url = URL(string: "\(judge0URL)?base64_encoded=false&wait=true") else {
            throw ResourceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(rapidAPIKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("judge0-ce.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        request.httpBody = try JSONSerialization.data(withJSONObject: submissionBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResourceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            print("⚠️ [CodeExec] HTTP \(httpResponse.statusCode)")
            throw ResourceError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(Judge0Response.self, from: data)

        print("✅ [CodeExec] Execution completed")

        return CodeExecutionResult(
            output: result.stdout ?? result.stderr ?? "No output",
            error: result.stderr,
            status: result.status.description,
            time: result.time ?? "0",
            memory: result.memory ?? 0
        )
    }

    /// Execute JavaScript code (client-side simulation)
    func executeJavaScript(code: String) async -> CodeExecutionResult {
        print("💻 [CodeExec] Simulating JavaScript execution...")

        // For security, we'll do basic simulation rather than actual eval
        // In production, you'd use a proper sandbox

        if code.contains("console.log") {
            // Extract content from console.log
            if let range = code.range(of: "console.log\\((.+)\\)", options: .regularExpression) {
                let output = String(code[range]).replacingOccurrences(of: "console.log(", with: "").replacingOccurrences(of: ")", with: "")
                return CodeExecutionResult(
                    output: output.trimmingCharacters(in: .whitespaces),
                    error: nil,
                    status: "Success",
                    time: "0.01",
                    memory: 1024
                )
            }
        }

        return CodeExecutionResult(
            output: "// JavaScript execution simulated\n// Add actual sandbox for production",
            error: nil,
            status: "Simulated",
            time: "0.00",
            memory: 512
        )
    }
}

struct Judge0Response: Codable {
    let stdout: String?
    let stderr: String?
    let status: Judge0Status
    let time: String?
    let memory: Int?
}

struct Judge0Status: Codable {
    let id: Int
    let description: String
}

struct CodeExecutionResult {
    let output: String
    let error: String?
    let status: String
    let time: String
    let memory: Int
}

// MARK: - Progress Persistence Service

class LearningProgressService {
    static let shared = LearningProgressService()
    private init() {}

    private let defaults = UserDefaults.standard
    private let progressKey = "learning_progress"

    func saveProgress(courseId: String, lessonIndex: Int, progress: Double) {
        var allProgress = loadAllProgress()
        allProgress[courseId] = CourseProgress(
            courseId: courseId,
            currentLessonIndex: lessonIndex,
            progressPercentage: progress,
            lastAccessedAt: Date()
        )

        if let encoded = try? JSONEncoder().encode(allProgress) {
            defaults.set(encoded, forKey: progressKey)
            print("💾 [Progress] Saved: \(courseId) - Lesson \(lessonIndex)")
        }
    }

    func loadProgress(courseId: String) -> CourseProgress? {
        let allProgress = loadAllProgress()
        return allProgress[courseId]
    }

    func loadAllProgress() -> [String: CourseProgress] {
        guard let data = defaults.data(forKey: progressKey),
              let progress = try? JSONDecoder().decode([String: CourseProgress].self, from: data) else {
            return [:]
        }
        return progress
    }

    func clearProgress(courseId: String) {
        var allProgress = loadAllProgress()
        allProgress.removeValue(forKey: courseId)

        if let encoded = try? JSONEncoder().encode(allProgress) {
            defaults.set(encoded, forKey: progressKey)
            print("🗑️ [Progress] Cleared: \(courseId)")
        }
    }
}

struct CourseProgress: Codable {
    let courseId: String
    let currentLessonIndex: Int
    let progressPercentage: Double
    let lastAccessedAt: Date
}

// MARK: - Voice Narration Service

class VoiceNarrationService {
    static let shared = VoiceNarrationService()
    private init() {}

    private var speechSynthesizer: AVSpeechSynthesizer?

    func speak(_ text: String, rate: Float = 0.5) {
        // Initialize if needed
        if speechSynthesizer == nil {
            speechSynthesizer = AVSpeechSynthesizer()
        }

        // Stop any current speech
        speechSynthesizer?.stopSpeaking(at: .immediate)

        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = 0.8

        print("🔊 [Voice] Speaking: \(text.prefix(50))...")
        speechSynthesizer?.speak(utterance)
    }

    func stop() {
        speechSynthesizer?.stopSpeaking(at: .immediate)
    }

    func pause() {
        speechSynthesizer?.pauseSpeaking(at: .word)
    }

    func resume() {
        speechSynthesizer?.continueSpeaking()
    }

    var isSpeaking: Bool {
        speechSynthesizer?.isSpeaking ?? false
    }
}

// MARK: - Errors

enum ResourceError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case noResults
}

// MARK: - API Keys Extension

extension APIKeys {
    static var googleBooksAPIKey: String {
        // Add your Google Books API key here
        // Get one from: https://console.cloud.google.com/
        return ProcessInfo.processInfo.environment["GOOGLE_BOOKS_API_KEY"] ?? ""
    }

    static var youtubeAPIKey: String {
        // Add your YouTube Data API key here
        // Get one from: https://console.cloud.google.com/
        return ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"] ?? ""
    }

    static var rapidAPIKey: String {
        // Add your RapidAPI key for Judge0
        // Get one from: https://rapidapi.com/judge0-official/api/judge0-ce
        return ProcessInfo.processInfo.environment["RAPIDAPI_KEY"] ?? ""
    }
}

import AVFoundation
